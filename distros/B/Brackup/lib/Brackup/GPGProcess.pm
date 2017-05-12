package Brackup::GPGProcess;
use strict;
use warnings;
use Brackup::Util qw(tempfile_obj);
use POSIX qw(_exit);
use IO::File;

sub new {
    my ($class, $pchunk) = @_;

    my $destfh = tempfile_obj();
    my $destfn = $destfh->filename;

    my $no_fork = $ENV{BRACKUP_NOFORK} || 0;  # if true (perhaps on Windows?), then don't fork... do all inline.

    my $pid = $no_fork ? 0 : fork;
    if (!defined $pid) {
        die "Failed to fork: $!";
    }

    # caller (parent)
    if ($pid) {
        return bless {
            destfh    => $destfh,
            pid       => $pid,
            running   => 1,
        }, $class;
    }

    # child:  encrypt and exit(0)...
    $pchunk->root->encrypt($pchunk->raw_chunkref, $destfn);

    unless (-e $destfn) {
        # if the file's gone, that likely means the parent process
        # already terminated and unlinked our temp file, in
        # which case we should just exit (with error code), rather
        # than spewing error messages to stderr.
        POSIX::_exit(1);
    }
    unless (-s $destfn) {
        die "No data in encrypted output file";
    }

    if ($no_fork) {
        return bless {
            destfh => $destfh,
            pid    => 0,
        }, $class;
    }

    # Note: we have to do this, to avoid some END block, somewhere,
    # from cleaning up something or doing something.  probably tempfiles
    # being destroyed in File::Temp.
    POSIX::_exit(0);
}

sub pid { $_[0]{pid} }

sub running { $_[0]{running} }
sub note_stopped { $_[0]{running} = 0; }

sub chunkref {
    my ($self) = @_;
    die "Still running!" if $self->{running};
    die "No data in file" unless $self->size_on_disk;

    return $self->{destfh};
}

sub size_on_disk {
    my $self = shift;
    return -s $self->{destfh}->filename;
}

1;

