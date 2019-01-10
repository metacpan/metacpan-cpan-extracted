package Catmandu::BagIt::Payload;

our $VERSION = '0.234';

use Moo;
use IO::File;
use File::Copy;
use Path::Tiny qw();

has 'filename' => (is => 'ro');
has 'path'     => (is => 'ro');
has 'flag'     => (is => 'rw', default => 0);

sub from_any {
    my ($class,$filename,$handle) = @_;

    if (ref($handle) eq '') {
        return $class->from_string($filename,$handle);
    }
    elsif (ref($handle) =~ /^IO/) {
        return $class->from_io($filename,$handle);
    }
    elsif (ref($handle) eq 'CODE') {
        return $class->from_callback($filename,$handle);
    }
    else {
        die "unknown handle type `" . ref($handle) . "`";
    }
}

sub from_io {
    my ($class,$filename,$io) = @_;

    my $tempfile = Path::Tiny->tempfile(UNLINK => 0);

    copy($io, $tempfile);

    my $inst = $class->new(filename => $filename, path => "$tempfile");

    # Flag the file as new so that we know the temporary files need
    # to be moved to a new location later
    $inst->{is_new} = 1;

    return $inst;
}

sub from_string {
    my ($class,$filename,$str) = @_;

    my $tempfile = Path::Tiny->tempfile(UNLINK => 0);

    Path::Tiny::path($tempfile)->spew_utf8($str);

    my $inst = $class->new(filename => $filename, path => "$tempfile");

    # Flag the file as new so that we know the temporary files need
    # to be moved to a new location later
    $inst->{is_new} = 1;

    return $inst;
}

sub from_callback {
    my ($class,$filename,$callback) = @_;

    my $tempfile = Path::Tiny->tempfile(UNLINK => 0);

    my $fh = IO::File->new(">$tempfile") || die "failed to open $tempfile for writing";

    $callback->($fh);

    $fh->close;

    my $inst = $class->new(filename => $filename, path => "$tempfile");

    # Flag the file as new so that we know the temporary files need
    # to be moved to a new location later
    $inst->{is_new} = 1;

    return $inst;
}

sub open {
    my $self = shift;
    return IO::File->new($self->path) || die "failed to open `" . $self->path . "` for reading: $!";
}

sub is_new {
    my $self = shift;

    $self->{is_new};
}

1;

__END__
