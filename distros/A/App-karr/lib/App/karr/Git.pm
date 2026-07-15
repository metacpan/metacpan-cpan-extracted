# ABSTRACT: Git operations for karr sync (native via Git::Native + libgit2, with a git-CLI transport fallback)

package App::karr::Git;
our $VERSION = '0.401';
use strict;
use warnings;
use Path::Tiny qw( path );
use Try::Tiny;
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use YAML::XS qw( Dump Load );
use Git::Native;
use Git::Native::Signature;
use Git::Native::Credential;


sub new {
    my ( $class, %args ) = @_;
    return bless {
        dir => $args{dir} // '.',
    }, $class;
}

sub dir {
    my ($self) = @_;
    return path( $self->{dir} );
}

# The libgit2 exception text from the most recent remote operation that failed
# (fetch/push/pull). Native operations have no shell exit code, so callers
# report this instead of $?. When the git-CLI transport fallback ran (see
# _cli_transport below), this instead carries the real git-CLI stderr.
sub last_error {
    my ($self) = @_;
    return $self->{_last_error};
}

# ----- Native repository handle (lazy) -----

sub _repo {
    my ($self) = @_;
    return $self->{_repo} if $self->{_repo};
    return undef unless $self->is_repo;
    $self->{_repo} = Git::Native->open_ext( $self->dir->stringify );
    return $self->{_repo};
}

sub _signature {
    my ($self) = @_;
    # Reuse one signature per process; falls back if user.name/email unset.
    return $self->{_sig} if $self->{_sig};
    my $repo = $self->_repo or return;
    $self->{_sig} = try { $repo->signature_default }
                    catch {
                      Git::Native::Signature->new(
                        name  => $self->git_user_name  || 'karr',
                        email => $self->git_user_email || 'karr@localhost',
                      );
                    };
    return $self->{_sig};
}

# ----- Repo discovery -----

sub is_repo {
    my ($self) = @_;
    my $ok = try {
        # open_ext walks up to find a .git; throws on miss.
        Git::Native->open_ext( $self->dir->stringify );
        1;
    } catch { $self->{_last_error} = "$_"; 0 };
    return $ok;
}

sub repo_root {
    my ($self) = @_;
    my $repo = $self->_repo or return undef;
    # workdir is undef for bare repos; in that case fall back to gitdir.
    my $root = $repo->workdir // $repo->gitdir;
    $root =~ s{/+\z}{};
    return path($root);
}

# ----- User identity (read via native config, not via CLI) -----

sub _config_string {
    my ( $self, $key ) = @_;
    my $repo = $self->_repo or return '';
    my $val = try { $repo->config_string($key) } catch { undef };
    return defined $val ? $val : '';
}

sub git_user_email {
    my ($self) = @_;
    return $self->_config_string('user.email');
}

sub git_user_name {
    my ($self) = @_;
    return $self->_config_string('user.name');
}

sub git_user_identity {
    my ($self) = @_;
    my $name = $self->git_user_name;
    my $email = $self->git_user_email;
    return "$name <$email>" if $name && $email;
    return $email || $name || '';
}

# ----- Ref name validation -----

sub normalize_ref_name {
    my ( $self, $ref ) = @_;
    defined $ref or die "Ref name is required\n";
    $ref =~ s{^/+}{};
    return $ref =~ m{^refs/} ? $ref : "refs/$ref";
}

sub validate_helper_ref {
    my ( $self, $ref ) = @_;
    my $full_ref = $self->normalize_ref_name($ref);

    my @blocked = (
        'refs/heads/',
        'refs/tags/',
        'refs/remotes/',
        'refs/bisect/',
        'refs/replace/',
        'refs/karr/',
    );

    for my $prefix (@blocked) {
        die "Ref '$full_ref' is in a protected namespace\n"
            if index( $full_ref, $prefix ) == 0;
    }
    die "Ref '$full_ref' is in a protected namespace\n"
        if $full_ref eq 'refs/stash' || index( $full_ref, 'refs/stash/' ) == 0;

    # Native validity check via Git::Native.
    die "Ref '$full_ref' is not a valid git ref name\n"
        unless Git::Native->reference_name_is_valid($full_ref);

    return $full_ref;
}

# ----- Ref CRUD (the hotspot — was 4 fork/exec per write_ref) -----

sub write_ref {
    my ( $self, $ref, $content ) = @_;
    my $repo = $self->_repo or return;

    my $blob_oid = $repo->blob_create_frombuffer($content);
    my $tb       = $repo->tree_builder;
    $tb->insert(name => 'data', oid => $blob_oid, mode => 0100644);
    my $tree_oid = $tb->write;

    my $sig = $self->_signature;
    my $commit_oid = $repo->commit_create(
        tree       => $tree_oid,
        parents    => [],
        message    => 'karr ref update',
        author     => $sig,
        committer  => $sig,
    );

    $repo->reference_create( $ref, $commit_oid, force => 1 );
    return 1;
}

sub read_ref {
    my ( $self, $ref ) = @_;
    my $repo = $self->_repo or return '';
    my $content = try {
        return '' unless $repo->reference_exists($ref);
        my $r      = $repo->reference($ref);
        my $oid    = $r->target;
        return '' unless $oid;
        my $commit = $repo->commit($oid);
        my $tree   = $commit->tree;
        my $entry  = $tree->entry_by_name('data');
        return '' unless $entry;
        return $repo->blob( $entry->{oid} )->content;
    } catch { '' };
    # Match historical CLI behaviour: cat-file's trailing newline was chomped.
    chomp $content if defined $content;
    return $content;
}

sub ref_exists {
    my ( $self, $ref ) = @_;
    my $repo = $self->_repo or return 0;
    return $repo->reference_exists($ref) ? 1 : 0;
}

sub delete_ref {
    my ( $self, $ref ) = @_;
    my $repo = $self->_repo or return 0;
    try { $repo->reference_delete($ref) };
    return 1;
}

# ----- Remote / network ops: native via Git::Native::Remote -----

sub has_remote {
    my ( $self, $remote ) = @_;
    $remote //= 'origin';
    my $repo = $self->_repo or return 0;
    return $repo->has_remote($remote);
}

# Default credentials callback: SSH-agent → ~/.ssh/id_ed25519 → ~/.ssh/id_rsa
# → default → fail. Matches CLI `git`'s implicit auth chain.
sub _default_credentials_cb {
    my @tried;
    return sub {
        my (%args) = @_;
        my $user  = $args{username_from_url} || 'git';
        my $types = $args{allowed_types}    || 0;

        # GIT_CREDENTIAL_SSH_KEY = 1<<1 = 2
        if ( $types & 2 ) {
            return Git::Native::Credential->ssh_agent( username => $user )
                unless $tried[0]++;
            for my $k (qw( id_ed25519 id_rsa )) {
                my $priv = "$ENV{HOME}/.ssh/$k";
                next unless -r $priv;
                next if $tried[1]{$k}++;
                return Git::Native::Credential->ssh_key(
                    username    => $user,
                    private_key => $priv,
                    public_key  => "$priv.pub",
                    passphrase  => '',
                );
            }
        }
        # GIT_CREDENTIAL_DEFAULT = 1<<3 = 8
        if ( ( $types & 8 ) && !$tried[2]++ ) {
            return Git::Native::Credential->default;
        }
        return undef;   # PASSTHROUGH — give up
    };
}

sub fetch {
    my ( $self, $remote ) = @_;
    $remote //= 'origin';
    my $repo = $self->_repo or return 0;
    return 1 unless $repo->has_remote($remote);
    return try {
        my $r = $repo->remote($remote);
        $r->fetch(
            refspecs    => [],   # use configured refspecs
            credentials => _default_credentials_cb(),
        );
        1;
    } catch {
        $self->{_last_error} = "$_";
        $self->_cli_transport( 'fetch', $remote, [] );
    };
}

sub push {
    my ( $self, $remote, $refspec ) = @_;
    $remote //= 'origin';
    my $repo = $self->_repo or return 0;
    return 1 unless $repo->has_remote($remote);
    $refspec //= '+refs/karr/*:refs/karr/*';
    return try {
        my $r = $repo->remote($remote);
        $r->push(
            refspecs    => [$refspec],
            credentials => _default_credentials_cb(),
            prune       => 1,
        );
        1;
    } catch {
        $self->{_last_error} = "$_";
        $self->_cli_transport( 'push', $remote, [$refspec], prune => 1 );
    };
}

sub pull {
    my ( $self, $remote ) = @_;
    $remote //= 'origin';
    my $repo = $self->_repo or return 0;
    return 1 unless $repo->has_remote($remote);
    return try {
        my $r = $repo->remote($remote);
        $r->fetch(
            refspecs    => ['refs/karr/*:refs/karr/*'],
            credentials => _default_credentials_cb(),
        );
        1;
    } catch {
        $self->{_last_error} = "$_";
        $self->_cli_transport( 'fetch', $remote, ['refs/karr/*:refs/karr/*'] );
    };
}

sub push_ref {
    my ( $self, $ref, $remote ) = @_;
    $remote //= 'origin';
    $ref = $self->validate_helper_ref($ref);
    my $repo = $self->_repo or return 0;
    return 1 unless $repo->has_remote($remote);
    return try {
        my $r = $repo->remote($remote);
        $r->push(
            refspecs    => ["+$ref:$ref"],
            credentials => _default_credentials_cb(),
        );
        1;
    } catch {
        $self->{_last_error} = "$_";
        $self->_cli_transport( 'push', $remote, ["+$ref:$ref"] );
    };
}

sub pull_ref {
    my ( $self, $ref, $remote ) = @_;
    $remote //= 'origin';
    $ref = $self->validate_helper_ref($ref);
    my $repo = $self->_repo or return 0;
    return 1 unless $repo->has_remote($remote);
    return try {
        my $r = $repo->remote($remote);
        $r->fetch(
            refspecs    => ["$ref:$ref"],
            credentials => _default_credentials_cb(),
        );
        1;
    } catch {
        $self->{_last_error} = "$_";
        $self->_cli_transport( 'fetch', $remote, ["$ref:$ref"] );
    };
}

# Fallback transport via the system `git` CLI so that ssh-config directives
# libgit2 ignores (ProxyCommand, Host aliases, IdentityFile, insteadOf) are
# honoured. Returns 1 on success, 0 on failure (setting _last_error to the real
# git-CLI stderr). $verb is 'push' or 'fetch'. @$refspecs may be empty
# (fetch => configured refspecs). %opt: prune => bool. Disabled by
# KARR_NO_CLI_FALLBACK=1.
sub _cli_transport {
    my ( $self, $verb, $remote, $refspecs, %opt ) = @_;
    return 0 if $ENV{KARR_NO_CLI_FALLBACK};

    my @cmd = ( 'git', '-C', $self->dir->stringify, $verb );
    CORE::push @cmd, '--prune' if $opt{prune};
    CORE::push @cmd, $remote, @$refspecs;

    my ( $err, $exit );
    my $ok = try {
        local $ENV{GIT_TERMINAL_PROMPT} = 0;   # never hang on an interactive prompt
        my $err_fh = gensym;
        my $pid = open3( my $in, my $out_fh, $err_fh, @cmd );
        close $in;
        local $/;
        my $out = <$out_fh>;                    # drained so the child can exit
        $err = <$err_fh>;
        waitpid( $pid, 0 );
        $exit = $? >> 8;
        1;
    } catch {
        $self->{_last_error} =
            "git CLI fallback unavailable: $_"
          . ( defined $self->{_last_error} ? " (native: $self->{_last_error})" : '' );
        0;
    };
    return 0 unless $ok;
    return 1 if defined $exit && $exit == 0;

    my $detail = defined $err ? $err : '';
    $detail =~ s/\s+\z//;
    $self->{_last_error} = "git $verb (CLI fallback) failed: $detail";
    return 0;
}

# ----- Task / config refs (sit on top of write_ref/read_ref) -----

sub save_task_ref {
  my ($self, $task) = @_;
  my $ref = "refs/karr/tasks/" . $task->id . "/data";
  $self->write_ref($ref, $task->to_markdown);
}

sub load_task_ref {
  my ($self, $id) = @_;
  my $ref = "refs/karr/tasks/$id/data";
  my $content = $self->read_ref($ref);
  return undef unless $content;
  require App::karr::Task;
  return App::karr::Task->from_string($content);
}

sub list_task_refs {
  my ($self) = @_;
  my %ids;
  for my $ref ( $self->list_refs('refs/karr/tasks/') ) {
    $ids{$1} = 1 if $ref =~ m{refs/karr/tasks/(\d+)/};
  }
  return sort { $a <=> $b } keys %ids;
}

sub list_refs {
    my ( $self, $prefix ) = @_;
    $prefix //= 'refs/karr/';
    my $repo = $self->_repo or return ();
    # Glob to scope the iterator server-side.
    my $names = $repo->reference_names( glob => "$prefix*" );
    return @$names;
}

sub ref_oids {
    my ( $self, $prefix ) = @_;
    $prefix //= 'refs/karr/';
    my $repo = $self->_repo or return undef;
    my %oids;
    for my $ref ( $self->list_refs($prefix) ) {
        my $oid = try {
            my $t = $repo->reference($ref)->target;
            $t ? $t->hex : undef;
        } catch { undef };
        $oids{$ref} = $oid if defined $oid;
    }
    return \%oids;
}

sub read_config_ref {
    my ($self) = @_;
    my $content = $self->read_ref('refs/karr/config');
    return {} unless $content;
    return Load($content);
}

sub write_config_ref {
    my ( $self, $data ) = @_;
    return $self->write_ref( 'refs/karr/config', Dump($data) );
}

sub read_next_id_ref {
    my ($self) = @_;
    my $content = $self->read_ref('refs/karr/meta/next-id');
    return 1 unless length $content;
    $content =~ s/\s+\z//;
    return $content =~ /^\d+$/ ? int($content) : 1;
}

sub write_next_id_ref {
    my ( $self, $next_id ) = @_;
    return $self->write_ref( 'refs/karr/meta/next-id', "$next_id\n" );
}

sub delete_refs {
    my ( $self, $prefix ) = @_;
    for my $ref ( $self->list_refs($prefix) ) {
        $self->delete_ref($ref);
    }
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Git - Git operations for karr sync (native via Git::Native + libgit2, with a git-CLI transport fallback)

=head1 VERSION

version 0.401

=head1 SYNOPSIS

    my $git = App::karr::Git->new(dir => '.');

    $git->pull;
    my @ids = $git->list_task_refs;
    my $task = $git->load_task_ref($ids[0]);

=head1 DESCRIPTION

L<App::karr::Git> provides the low-level Git interface used by C<karr> for
syncing board state through C<refs/karr/*>. Local object/ref ops (read/write/
delete of refs, blobs, trees, commits) run natively via L<Git::Native> (FFI
to libgit2) with no fork/exec. SSH-agent and HTTPS-token credentials are
supplied through the libgit2 credential-acquire callback.

Network fetch/push (C<fetch>, C<pull>, C<push>, C<push_ref>, C<pull_ref>)
also try the native libgit2 transport first. If that transport fails, they
fall back to the system C<git> CLI (via L<IPC::Open3>), because libgit2/
libssh2 doesn't read C<~/.ssh/config> and can't run a C<ProxyCommand> —
directives like C<Host> aliases, C<IdentityFile>, and C<insteadOf> only take
effect through the CLI. Set C<KARR_NO_CLI_FALLBACK=1> to disable the
fallback and surface native transport failures directly.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::BoardStore>, L<App::karr::Task>,
L<App::karr::Config>, L<Git::Native>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
