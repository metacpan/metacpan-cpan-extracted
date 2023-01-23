package BioX::Seq::Stream;

use 5.012;
use strict;
use warnings;

use IPC::Cmd qw/can_run/;
use Scalar::Util qw/blessed openhandle/;
use BioX::Seq;
use POSIX qw/ceil/;
use Cwd qw/abs_path/;
use File::Basename qw/fileparse/;

# define or search for binary locations
# if these are not available
our $GZIP_BIN = can_run('pigz')   // can_run('gzip');
our $BZIP_BIN = can_run('pbzip2') // can_run('bzip2');
our $ZSTD_BIN = can_run('pzstd')  // can_run('zstd');
our $DSRC_BIN = can_run('dsrc2')  // can_run('dsrc');
our $FQZC_BIN = can_run('fqz_comp');
our $XZ_BIN   = can_run('xz');

use constant MAGIC_GZIP => pack('C3', 0x1f, 0x8b, 0x08);
use constant MAGIC_DSRC => pack('C2', 0xaa, 0x02);
use constant MAGIC_BZIP => 'BZh';
use constant MAGIC_FQZC => '.fqz';
use constant MAGIC_BAM  => pack('C4', 0x42, 0x41, 0x4d, 0x01);
use constant MAGIC_2BIT => pack('C4', 0x1a, 0x41, 0x27, 0x43);
use constant MAGIC_ZSTD => pack('C4', 0x28, 0xB5, 0x2F, 0xFD);
use constant MAGIC_XZ   => pack('C6', 0xfd, 0x37, 0x7a, 0x58, 0x5a, 0x00);

sub new {

    my ($class,$fn, %args) = @_;

    my $self = bless {} => $class;

    # 'fast' mode turns off parser sanity-checking in places
    if ($args{fast}) {
        $self->fast( $args{fast} );
    }

    if (defined $fn) {

        my $fh = openhandle($fn); # can pass filehandle too;
        if (! defined $fh) { # otherwise assume filename
            
            #if passed a filename, try to determine if compressed
            open $fh, '<', $fn or die "Error opening $fn for reading\n";

            #read first six bytes as raw
            #this causes a memory leak as opened filehandles are not properly
            #closed again. Should work without setting binary mode anyway.
            #my $old_layers = join '', map {":$_"} PerlIO::get_layers($fh);
            #binmode($fh);
            read( $fh, my $magic, 6 );
            #binmode($fh, $old_layers); 

            #check for compression and open stream if found
            if (substr($magic,0,3) eq MAGIC_GZIP) {
                close $fh;
                if (! defined $GZIP_BIN) {
                    # fall back on Perl-based method (but can be SLOOOOOW!)
                    require IO::Uncompress::Gunzip;
                    $fh = IO::Uncompress::Gunzip->new($fn, MultiStream => 1);
                }
                else {
                    open $fh, '-|', $GZIP_BIN, '-dc', $fn
                        or die "Error opening gzip stream: $!\n";
                }
            }
            elsif (substr($magic,0,3) eq MAGIC_BZIP) {
                close $fh;
                if (! defined $BZIP_BIN) {
                    # fall back on Perl-based method (but can be SLOOOOOW!)
                    require IO::Uncompress::Bunzip2;
                    $fh = IO::Uncompress::Bunzip2->new($fn, MultiStream => 1);
                }
                else {
                    open $fh, '-|', $BZIP_BIN, '-dc', $fn
                        or die "Error opening bzip2 stream: $!\n";
                }
            }
            elsif (substr($magic,0,4) eq MAGIC_ZSTD) {
                die "no zstd backend found\n" if (! defined $ZSTD_BIN);
                close $fh;
                open $fh, '-|', $ZSTD_BIN, '-dc', $fn
                    or die "Error opening zstd stream: $!\n";
            }
            elsif (substr($magic,0,2) eq MAGIC_DSRC) {
                die "no dsrc backend found\n" if (! defined $DSRC_BIN);
                close $fh;
                open $fh, '-|', $DSRC_BIN, 'd', '-s', $fn
                    or die "Error opening dsrc stream: $!\n";
            }
            elsif (substr($magic,0,4) eq MAGIC_FQZC) {
                die "no fqz backend found\n" if (! defined $FQZC_BIN);
                close $fh;
                open $fh, '-|', $FQZC_BIN, '-d', $fn
                    or die "Error opening fqz_comp stream: $!\n";
            }
            elsif (substr($magic,0,6) eq MAGIC_XZ) {
                die "no xz backend found\n" if (! defined $XZ_BIN);
                close $fh;
                open $fh, '-|', $XZ_BIN, '-dc', $fn
                    or die "Error opening xz stream: $!\n";
            }
            else {
                seek($fh,0,0);
            }

        }
        $self->{fh} = $fh;

    }
    else {
        $self->{fh} = \*STDIN;
    }

    # handle files coming from different platforms
    #my @layers = PerlIO::get_layers($self->{fh});
    #binmode($self->{fh},':unix:stdio:crlf');

    $self->_guess_format;

    $self->_init;

    return $self;

}

sub fast {

    my ($self, $bool) = @_;
    $self->{fast} = $bool // 1;

}

sub _guess_format {

    my ($self) = @_;

    # Filetype guessing must be based on first two bytes (or less)
    # which are stored in an object buffer
    my $r = (read $self->{fh}, $self->{buffer}, 2);
    die "failed to read initial bytes" if ($r != 2);

    my $search_path = abs_path(__FILE__);
    $search_path =~ s/\.pm$//i;
    my @matched;
    for my $module ( glob "$search_path/*.pm" ) {
        my ($name,$path,$suff) = fileparse($module, qr/\.pm/i);
        my $classname = blessed($self) . "::$name";
        eval "require $classname";
        if ($classname->_check_type($self)) {
            push @matched, $classname;
        }
    }

    die "Failed to guess filetype\n"   if (scalar(@matched) < 1);
    # uncoverable branch true
    die "Multiple filetypes matched\n" if (scalar(@matched) > 1);

    eval "require $matched[0]";
    bless $self => $matched[0];

}


1;


__END__

=head1 NAME

BioX::Seq::Stream - Parse FASTA and FASTQ files sequentially

=head1 SYNOPSIS

    use BioX::Seq::Stream;

    my $parser = BioX::Seq::Stream->new; #defaults to STDIN
    my $parser = BioX::Seq::Stream->new( $filename );
    my $parser = BioX::Seq::Stream->new( $filehandle );

    while (my $seq = $parser->next_seq) {

        # $seq is a BioX::Seq object

    }

=head1 DESCRIPTION

C<BioX::Seq::Stream> is a sequential parser for FASTA and FASTQ files. It
should handle any valid input, with the exception of the use of semi-colons to
indicate FASTA comments (this could be easily implemented, but I have never
seen an actual FASTA file like this in the wild, and the NCBI FASTA
specification does not allow for this usage). In particular, it will properly
handle FASTQ files with multi-line (wrapped) sequence and quality strings. I
have never seen a FASTQ file like this either, but apparently this is
technically valid and a few software programs will still create files like
this.

=head1 CONSTRUCTOR

=head2 new

    my $parser = BioX::Seq::Stream->new();
    my $parser = BioX::Seq::Stream->new( $filename );
    my $parser = BioX::Seq::Stream->new( $filehandle );
    my $parser = BioX::Seq::Stream->new( $filename, %args );

Create a new C<BioX::Seq::Stream> parser. If no arguments are given (or if the
first argument given has an undefined value), the parser will read from STDIN.
Otherwise, the parser will determine whether a filename or a filehandle is
provided and act accordingly. Returns a C<BioX::Seq::Stream> parser object.

The first argument is always a filename or filehandle. Subsequent key/value
arguments can include:

=over 4

=item fast

    my $parser = BioX::Seq::Stream->new( $filename, fast => 1 );

In version 0.007004, a check was added during FASTA parsing which validated
each sequence string. Previously, no validation had been performed for the
sake of speed. The new check, while safer, results in somewhat slower parsing.
It can be explictly turned off by setting this parameter to a true value. This
can also be toggled explictly using the \C<fast()> method described below.

=back

=head1 METHODS

=head2 next_seq

    while (my $seq = $parser->next_seq()) {
        # do something
    }

Reads the next sequence from the filehandle. Returns a C<BioX::Seq> object, or
I<undef> if the end of the file is reached.

The first time this is called, the parser will try to automatically determine
the file format and throw an exception if detection fails. In practice this
should seldom or never happen, as the supported file formats can be reliable
distinguished based on the first few bytes of the file.

=head2 fast

    $parser->fast(1);
    $parser->fast(); # same as $parser->fast(1);
    $parser->fast(0);

Sets/unsets 'fast' mode. If a true valid is given (or no value at all),
certain validation steps during parsing are disabled for the sake of speed, as
described above under CONSTRUCTOR.

=head1 DECOMPRESSION

If a filename is passed to the constructor, the module will read the first
four bytes and match against known file compression magic bytes. If a
compressed file is suspected, and a compatible decompression program can be
found in the system path, a piped filehandle is opened for reading.
Currently the following formats are supported (if appropriate binaries are
found):

  * GZIP

  * BZIP2

  * DSRC v2 (released versions buggy, currently not under testing!!)

  * FQZCOMP

Benchmarking indicated a fairly significant speed difference in handling
decompression using external binaries vs. Perl modules, so the current
implementation uses the former for decompressing on-the-fly. This may require
additional work to compile to proper binaries for a given platform. This
module will try to find the location of the proper binaries by their typical
name. If installed using a non-standard name, the following package variables
can be set:

=over 4

=item $BioX::Seq::Stream::GZIP_BIN

By default, looks for a binary in PATH named 'pigz' or 'gzip'

=item $BioX::Seq::Stream::BZIP_BIN

By default, looks for a binary in PATH named 'pbzip2' or 'bzip2'

=item $BioX::Seq::Stream::DSRC_BIN

By default, looks for a binary in PATH named 'dsrc2' or 'dsrc'

=item $BioX::Seq::Stream::FQZC_BIN

By default, looks for a binary in PATH named 'fqz_comp'

=back

=head1 CAVEATS AND BUGS

Minimal input validation is performed. FASTQ ID lines are checked for proper
format and sequence and quality lengths are compared, but the contents of
sequence and quality strings are not sanity-checked, nor is the FASTA sequence
string.

Please reports bugs to the author.

=head1 AUTHOR

Jeremy Volkening <jeremy *at* base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2014-2016 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

