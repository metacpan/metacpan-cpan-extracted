# ABSTRACT: Git operations for karr sync (via CLI)

package App::karr::Git;
our $VERSION = '0.003';
use strict;
use warnings;
use Path::Tiny qw( path );
use IPC::Open2;

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

sub _git_cmd {
    my ($self, @cmd) = @_;
    my $dir = $self->dir->stringify;
    my $pid = open(my $fh, '-|');
    if (!defined $pid) {
        die "fork failed: $!";
    }
    if (!$pid) {
        open(STDERR, '>', '/dev/null');
        chdir $dir or die "chdir $dir: $!";
        exec('git', @cmd) or die "exec git: $!";
    }
    my $output = do { local $/; <$fh> };
    close $fh;
    my $ok = $? == 0;
    chomp $output if defined $output;
    return wantarray ? ($output, $ok) : $output;
}

sub _git_cmd_stdin {
    my ($self, $input, @cmd) = @_;
    my $dir = $self->dir->stringify;
    my $pid = open2(my $out_fh, my $in_fh, 'git', '-C', $dir, @cmd);
    print $in_fh $input;
    close $in_fh;
    my $output = do { local $/; <$out_fh> };
    waitpid($pid, 0);
    chomp $output if defined $output;
    return $output;
}

sub is_repo {
    my ($self) = @_;
    my ($out, $ok) = $self->_git_cmd('rev-parse', '--show-toplevel');
    return $ok;
}

sub git_user_email {
    my ($self) = @_;
    my ($email, $ok) = $self->_git_cmd('config', '--get', 'user.email');
    return $ok ? $email : '';
}

sub git_user_name {
    my ($self) = @_;
    my ($name, $ok) = $self->_git_cmd('config', '--get', 'user.name');
    return $ok ? $name : '';
}

sub git_user_identity {
    my ($self) = @_;
    my $name = $self->git_user_name;
    my $email = $self->git_user_email;
    return "$name <$email>" if $name && $email;
    return $email || $name || '';
}

sub write_ref {
    my ( $self, $ref, $content ) = @_;

    # Create blob from content via stdin
    my $blob = $self->_git_cmd_stdin($content, 'hash-object', '-w', '--stdin');
    return unless $blob;

    # Create tree containing the blob as "data"
    my $tree_line = sprintf("100644 blob %s\tdata", $blob);
    my $tree = $self->_git_cmd_stdin($tree_line, 'mktree');
    return unless $tree;

    # Create commit wrapping the tree
    my $commit = $self->_git_cmd('commit-tree', $tree, '-m', 'karr ref update');
    return unless $commit;

    # Point ref at commit
    $self->_git_cmd('update-ref', $ref, $commit);
    return 1;
}

sub read_ref {
    my ( $self, $ref ) = @_;
    my ($content, $ok) = $self->_git_cmd('cat-file', '-p', "$ref:data");
    return $ok ? $content : '';
}

sub delete_ref {
    my ( $self, $ref ) = @_;
    $self->_git_cmd('update-ref', '-d', $ref);
    return 1;
}

sub fetch {
    my ( $self, $remote ) = @_;
    $remote //= 'origin';
    my (undef, $ok) = $self->_git_cmd('fetch', $remote);
    return $ok;
}

sub push {
    my ( $self, $remote, $refspec ) = @_;
    $remote //= 'origin';
    $refspec //= 'refs/karr/*:refs/karr/*';
    my (undef, $ok) = $self->_git_cmd('push', $remote, $refspec);
    return $ok;
}

sub pull {
    my ( $self, $remote ) = @_;
    $remote //= 'origin';
    my (undef, $ok) = $self->_git_cmd('fetch', $remote, 'refs/karr/*:refs/karr/*');
    return $ok;
}

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
    my $output = $self->_git_cmd('for-each-ref', '--format=%(refname)', 'refs/karr/tasks/');
    return () unless $output;
    my %ids;
    for (split /\n/, $output) {
        $ids{$1} = 1 if m{refs/karr/tasks/(\d+)/};
    }
    return sort { $a <=> $b } keys %ids;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Git - Git operations for karr sync (via CLI)

=head1 VERSION

version 0.003

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-karr/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
