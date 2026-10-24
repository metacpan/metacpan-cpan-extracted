package App::FileSync::Store;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;

use App::FileSync qw(json_encode json_decode read_text write_atomic validate_relpath set_mtime);
use App::FileSync::Config;
use App::FileSync::Ignore;
use App::FileSync::Lock;
use App::FileSync::Scan;
use App::FileSync::Trash;

sub new {
    my ($class, %args) = @_;

    my $root = $args{root};
    my $repo = $args{repo};
    die "Store: no root given\n" unless defined $root && length $root;
    die "Store: no repo given\n" unless defined $repo && length $repo;

    my $config = $args{config} || App::FileSync::Config::load_repo($root, $repo);

    return bless {
        root   => $root,
        repo   => $repo,
        config => $config,
        ignore => App::FileSync::Ignore->new(patterns => $config->{ignore}),
    }, $class;
}

sub root    { $_[0]{root} }
sub repo    { $_[0]{repo} }
sub config  { $_[0]{config} }

sub master_dir {
    my ($self) = @_;
    return File::Spec->catdir($self->{root}, 'master', $self->{repo});
}

sub meta_dir {
    my ($self) = @_;
    return App::FileSync::Config::repo_meta_dir($self->{root}, $self->{repo});
}

sub index_path {
    my ($self) = @_;
    return File::Spec->catfile($self->meta_dir(), 'master.json');
}

sub base_path {
    my ($self, $client) = @_;
    die "Store: no client id\n" unless defined $client && length $client;
    return File::Spec->catfile($self->meta_dir(), 'clients', "$client.json");
}

sub trash_dir {
    my ($self) = @_;
    return File::Spec->catdir($self->meta_dir(), 'trash');
}

sub journal_path {
    my ($self) = @_;
    my @t = gmtime();
    return File::Spec->catfile($self->meta_dir(), 'journal',
        sprintf('%04d-%02d.jsonl', $t[5] + 1900, $t[4] + 1));
}

sub lock_path {
    my ($self) = @_;
    return File::Spec->catfile($self->meta_dir(), 'locks', 'repo.lock');
}

sub acquire_lock {
    my ($self) = @_;
    return App::FileSync::Lock::acquire(path => $self->lock_path(), nonblock => 1);
}

sub abs_path {
    my ($self, $rel) = @_;

    my ($ok, $reason) = validate_relpath($rel);
    die "Unsafe path '$rel': $reason\n" unless $ok;

    $self->_assert_no_symlinked_parent($rel);

    return File::Spec->catfile($self->master_dir(), split m{/}, $rel);
}

sub _assert_no_symlinked_parent {
    my ($self, $rel) = @_;

    my @parts = split m{/}, $rel;
    pop @parts;

    my $current = $self->master_dir();
    for my $part (@parts) {
        $current = File::Spec->catfile($current, $part);
        last unless -e $current || -l $current;
        die "Refusing to write through symlinked directory $current\n" if -l $current;
    }

    return 1;
}

sub load_index {
    my ($self) = @_;
    return $self->_load_entries($self->index_path());
}

sub save_index {
    my ($self, $entries) = @_;
    return $self->_save_entries($self->index_path(), $entries);
}

sub load_base {
    my ($self, $client) = @_;
    return $self->_load_entries($self->base_path($client));
}

sub save_base {
    my ($self, $client, $entries) = @_;
    return $self->_save_entries($self->base_path($client), $entries);
}

sub _load_entries {
    my ($self, $path) = @_;
    return {} unless -e $path;

    my $document = eval { json_decode(read_text($path)) };
    die "Cannot parse $path: $@" if $@;

    return {} unless ref($document) eq 'HASH';
    return ref($document->{entries}) eq 'HASH' ? $document->{entries} : {};
}

sub _save_entries {
    my ($self, $path, $entries) = @_;
    write_atomic($path, json_encode({
        version => 1,
        entries => $entries || {},
    }) . "\n");
    return 1;
}

# Walk the master, reusing indexed hashes where size and mtime still match.
sub walk_master {
    my ($self, $cache) = @_;

    my $master = $self->master_dir();
    die "Master directory is missing: $master\n" unless -d $master;

    my ($manifest, $stats, $skipped) = App::FileSync::Scan::scan(
        root   => $master,
        ignore => $self->{ignore},
        cache  => $cache || {},
    );

    return ($manifest, $stats, $skipped);
}

sub ensure_parent {
    my ($self, $rel) = @_;

    my $abs = $self->abs_path($rel);
    my $parent = dirname($abs);
    make_path($parent) unless -d $parent;

    return $parent;
}

sub clear_target {
    my ($self, $abs) = @_;

    if (-l $abs) {
        unlink $abs or die "Cannot remove symlink $abs: $!\n";
    } elsif (-d $abs) {
        rmdir $abs or die "Cannot replace non-empty directory $abs\n";
    } elsif (-e $abs) {
        unlink $abs or die "Cannot remove $abs: $!\n";
    }

    return 1;
}

sub temp_path {
    my ($self, $rel) = @_;

    my $abs = $self->abs_path($rel);
    my $dir = dirname($abs);
    make_path($dir) unless -d $dir;

    return File::Spec->catfile($dir, '.filesync-tmp-' . $$ . '-' . int(rand(1_000_000)));
}

# Move a verified temporary file into place, preserving mtime and mode.
sub commit_temp {
    my ($self, $rel, $temp, $mtime, $mode) = @_;

    my $abs = $self->abs_path($rel);

    chmod($mode & 07777, $temp) if defined $mode && $^O ne 'MSWin32';
    set_mtime($temp, $mtime);

    $self->clear_target($abs);

    rename($temp, $abs) or do {
        my $error = $!;
        unlink $temp;
        die "Cannot move $temp into place at $abs: $error\n";
    };

    return $abs;
}

sub move_to_trash {
    my ($self, $rel, $epoch) = @_;

    my $abs = $self->abs_path($rel);
    return undef unless -e $abs || -l $abs;

    return App::FileSync::Trash::move_to_trash(
        src   => $abs,
        rel   => $rel,
        root  => $self->trash_dir(),
        epoch => defined $epoch ? $epoch : time,
    );
}

sub clean_stale_temps {
    my ($self, %args) = @_;

    my $master = $self->master_dir();
    return 0 unless -d $master;

    return App::FileSync::Scan::clean_stale_temps(
        root    => $master,
        max_age => defined $args{max_age} ? $args{max_age} : 3600,
    );
}

sub prune_trash {
    my ($self, %args) = @_;

    return App::FileSync::Trash::prune(
        root    => $self->trash_dir(),
        days    => defined $args{days} ? $args{days} : ($self->{config}{trash_days} || 30),
        dry_run => $args{dry_run},
    );
}

sub journal {
    my ($self, $event) = @_;

    my $path = $self->journal_path();
    make_path(dirname($path)) unless -d dirname($path);

    open my $fh, '>>', $path or die "Cannot append to journal $path: $!\n";
    print { $fh } json_encode({ ts => time, %{$event} }), "\n"
        or die "Cannot write to journal $path: $!\n";
    close $fh or die "Cannot close journal $path: $!\n";

    return 1;
}

1;
