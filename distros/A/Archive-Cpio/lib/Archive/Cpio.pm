package Archive::Cpio;

use strict;
use warnings;

our $VERSION = '0.10';

use Archive::Cpio::Common;
use Archive::Cpio::File;
use Archive::Cpio::OldBinary;

=head1 NAME

Archive::Cpio - module for manipulations of cpio archives

=head1 SYNOPSIS

    use Archive::Cpio;

    # simple example removing entry "foo"

    my $cpio = Archive::Cpio->new;
    $cpio->read($file);
    $cpio->remove('foo');
    $cio->write($file);

     # more complex example, filtering on the fly

    my $cpio = Archive::Cpio->new;
    $cpio->read_with_handler(\*STDIN,
                sub {
                    my ($e) = @_;
                    if ($e->name ne 'foo') {
                        $cpio->write_one(\*STDOUT, $e);
                    }
                });
    $cpio->write_trailer(\*STDOUT);

=head1 DESCRIPTION

Archive::Cpio provides a few functions to read and write cpio files.

=cut


=head2 Archive::Cpio->new()

Create an object

=cut

sub new {
    my ($class, %options) = @_;
    bless \%options, $class;
}

=head2 $cpio->read($filename)

=head2 $cpio->read($filehandle)

Reads the cpio file

=cut

sub read {
    my ($cpio, $file) = @_;

    my $IN;
    if (ref $file) {
        $IN = $file;
    } else {
        open($IN, '<', $file) or die "can't open $file: $!\n";
    }

    read_with_handler($cpio, $IN, sub {
        my ($e) = @_;
        push @{$cpio->{list}}, $e;
    });
}

=head2 $cpio->write($filename)

=head2 $cpio->write($filehandle)

Writes the entries and the trailer

=cut

sub write {
    my ($cpio, $file, $fmt) = @_;

    my $OUT;
    if (ref $file) {
        $OUT = $file;
    } else {
        open($OUT, '>', $file) or die "can't open $file: $!\n";
    }

    # Set the format if not done or if specified
    if (!$cpio->{archive_format} || $fmt) {
        $cpio->{archive_format} = _create_archive_format($fmt || 'ODC');
    }

    $cpio->write_one($OUT, $_) foreach @{$cpio->{list}};
    $cpio->write_trailer($OUT);
}

=head2 $cpio->remove(@filenames)

Removes any entries with names matching any of the given filenames from the in-memory archive

=cut

sub remove {
    my ($cpio, @filenames) = @_;
    $cpio->{list} or die "can't remove from nothing\n";

    my %filenames = map { $_ => 1 } @filenames;

    @{$cpio->{list}} = grep { !$filenames{$_->name} } @{$cpio->{list}};
}

=head2 $cpio->get_files([ @filenames ])

Returns a list of C<Archive::Cpio::File> (after a C<$cpio->read>)

=cut

sub get_files {
    my ($cpio, @list) = @_;
    if (@list) {
        map { get_file($cpio, $_) } @list;
    } else {
        @{$cpio->{list}};
    }
}

=head2 $cpio->get_file($filename)

Returns the C<Archive::Cpio::File> matching C<$filename< (after a C<$cpio->read>)

=cut

sub get_file {
    my ($cpio, $file) = @_;
    foreach (@{$cpio->{list}}) {
        $_->name eq $file and return $_;
    }
    undef;
}

=head2 $cpio->add_data($filename, $data, $opthashref)

Takes a filename, a scalar full of data and optionally a reference to a hash with specific options.

Will add a file to the in-memory archive, with name C<$filename> and content C<$data>.
Specific properties can be set using C<$opthashref>.

=cut

sub add_data {
    my ($cpio, $filename, $data, $opthashref) = @_;
    my $entry = $opthashref || {};
    $entry->{name} = $filename;
    $entry->{data} = $data;
    $entry->{nlink} ||= 1;
    $entry->{mode} ||= 0100644;
    push @{$cpio->{list}}, Archive::Cpio::File->new($entry);
}

=head2 $cpio->read_with_handler($filehandle, $coderef)

Calls the handler function on each header. An C<Archive::Cpio::File> is passed as a parameter

=cut

sub read_with_handler {
    my ($cpio, $F, $handler) = @_;

    my $FHwp = Archive::Cpio::FileHandle_with_pushback->new($F);
    $cpio->{archive_format} = detect_archive_format($FHwp);

    while (my $entry = $cpio->{archive_format}->read_one($FHwp)) {
        $entry = Archive::Cpio::File->new($entry);
        $handler->($entry);
    }
}

=head2 $cpio->write_one($filehandle, $entry)

Writes a C<Archive::Cpio::File> (beware, a valid cpio needs a trailer using C<write_trailer>)

=cut

sub write_one {
    my ($cpio, $F, $entry) = @_;
    $cpio->{archive_format}->write_one($F, $entry);
}

=head2 $cpio->write_trailer($filehandle)

Writes the trailer to finish the cpio file

=cut

sub write_trailer {
    my ($cpio, $F) = @_;
    $cpio->{archive_format}->write_trailer($F);
}




sub _default_magic {
    my ($archive_format) = @_;
    my $magics = Archive::Cpio::Common::magics();
    my %format2magic = reverse %$magics;
    $format2magic{$archive_format} or die "unknown archive_format $archive_format\n";
}

sub _create_archive_format {
    my ($archive_format, $magic) = @_;

    $magic ||= _default_magic($archive_format);

    # perl_checker: require Archive::Cpio::NewAscii
    # perl_checker: require Archive::Cpio::OldBinary
    my $class = "Archive::Cpio::$archive_format";
    eval "require $class";
    return $class->new($magic);
}

sub detect_archive_format {
    my ($FHwp) = @_;

    my $magics = Archive::Cpio::Common::magics();

    my $max_length = max(map { length $_ } values %$magics);
    my $s = $FHwp->read_ahead($max_length);

    foreach my $magic (keys %$magics) {
        my $archive_format = $magics->{$magic};
        begins_with($s, $magic) or next;

        #warn "found magic for $archive_format\n";

        # perl_checker: require Archive::Cpio::NewAscii
        # perl_checker: require Archive::Cpio::OldBinary
        return _create_archive_format($archive_format, $magic);
    }
    die "invalid archive\n";
}

=head1 AUTHOR

Pascal Rigaux <pixel@mandriva.com>

=cut
