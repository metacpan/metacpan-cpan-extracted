package App::FileSync::Lock;

use strict;
use warnings;

use Fcntl qw(:flock);
use File::Basename qw(dirname);
use File::Path qw(make_path);

# Returns a filehandle holding the lock, or undef if another run has it.
sub acquire {
    my (%args) = @_;

    my $path = $args{path};
    die "Lock: no path given\n" unless defined $path && length $path;

    make_path(dirname($path)) unless -d dirname($path);

    open my $fh, '>>', $path or die "Cannot open lock file $path: $!\n";

    my $flags = LOCK_EX;
    $flags |= LOCK_NB if $args{nonblock};
    unless (flock($fh, $flags)) {
        close $fh;
        return undef;
    }

    return $fh;
}

1;
