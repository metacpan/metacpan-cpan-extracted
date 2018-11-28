package Archive::ByteBoozer;

=head1 NAME

Archive::ByteBoozer - Perl interface to David Malmborg's "ByteBoozer", a data cruncher for Commodore files

=head1 SYNOPSIS

  use Archive::ByteBoozer qw/crunch/;

  # Read file, crunch data, write crunched data into a file:
  my $original = new IO::File "original.prg", "r";
  my $crunched = new IO::File "crunched.prg", "w";
  crunch(source => $original, target => $crunched);

  # Read scalar, crunch data, write crunched data into a scalar:
  my @data = (0x00, 0x10, 0x01, 0x02, 0x03, 0x04, 0x05);
  my $original = join '', map { chr $_ } @data;
  my $crunched = new IO::Scalar;
  crunch(source => $original, target => $crunched);

  # Crunch data preceding it with the given initial address first:
  my $initial_address = 0x2000;
  crunch(source => $original, target => $crunched, precede_initial_address => $initial_address);

  # Crunch data replacing the first two bytes with the new initial address first:
  my $initial_address = 0x4000;
  crunch(source => $original, target => $crunched, replace_initial_address => $initial_address);

  # Attach decruncher with the given execute program address:
  my $program_address = 0x0c00;
  crunch(source => $original, target => $crunched, attach_decruncher => $program_address);

  # Relocate compressed data to the given start address:
  my $start_address = 0x0800;
  crunch(source => $original, target => $crunched, relocate_output => $start_address);

  # Relocate compressed data to the given end address:
  my $end_address = 0x2800;
  crunch(source => $original, target => $crunched, relocate_output_up_to => $end_address);

  # Enable verbose output while crunching data:
  my $verbose = 1;
  crunch(source => $original, target => $crunched, verbose => $verbose);

=head1 DESCRIPTION

David Malmborg's "ByteBoozer" is a data cruncher for Commodore files written in C. In Perl the following operations are implemented via C<Archive::ByteBoozer> package:

=over

=item *
Reading data from any given C<IO::> interface (including files, scalars, etc.)

=item *
Packing data using the compression algorithm implemented via ByteBoozer

=item *
Writing data into any given C<IO::> interface (including files, scalars, etc.)

=back

=head1 METHODS

=cut

use bytes;
use strict;
use warnings;

use base qw( Exporter );
our %EXPORT_TAGS = ();
$EXPORT_TAGS{'crunch'} = [ qw(&crunch) ];
$EXPORT_TAGS{'all'} = [ @{$EXPORT_TAGS{'crunch'}} ];
our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = qw();

our $VERSION = '0.10';

use Data::Dumper;
use IO::Scalar;
use Params::Validate qw(:all);
use Scalar::Util qw(looks_like_number refaddr);

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head2 crunch

In order to crunch the data, you are required to provide source and target C<IO::> interfaces:

  my $original = new IO::File "original.prg", "r";
  my $crunched = new IO::File "crunched.prg", "w";
  crunch(source => $original, target => $crunched);

Upon writing the data into the target C<IO::> interface current position in the stream will be reset to the initial position acquired before the subroutine call, which enables immediate access to the compressed data without the necessity of seeking to the right position in the stream. The same comment applies to the source C<IO::> interface.

In addition to the source and target C<IO::> interfaces, which are mandatory arguments to the C<crunch> subroutine call, the following parameters are recognized:

=head3 attach_decruncher

C<attach_decruncher> enables to attach decruncher procedure with the given program start address:

  my $program_address = 0x0c00;
  crunch(source => $in, target => $out, attach_decruncher => $program_address);

This will create an executable BASIC file that is by default loaded into the memory area beginning at $0801 (assuming no output relocation has been requested), and jumping directly to the given execute program address of $0c00 upon completion of the decrunching process.

=head3 make_executable

C<make_executable> is an alias for C<attach_decruncher>:

  my $program_address = 0x3600;
  crunch(source => $in, target => $out, make_executable => $program_address);

=head3 relocate_output

C<relocate_output> is used for setting up a new start address of the compressed data (by default data is shifted and aligned to fill in the memory up to the address of $fff9):

    my $start_address = 0x0800;
    crunch(source => $in, target => $out, relocate_output => $start_address);

This will relocate compressed data to the given start address of $0800 by writing an appropriate information in the output stream.

=head3 relocate_output_up_to

C<relocate_output_up_to> is used for setting up a new start address of the compressed data by shifting it up to the given end address (by default data is shifted and aligned to fill in the memory up to the address of $fff9, however you might want to align your data to a different end address - it is where this option becomes handy):

  my $end_address = 0x2800;
  crunch(source => $original, target => $crunched, relocate_output_up_to => $end_address);

This will relocate compressed data to some address below $2800 by writing an appropriate information in the output stream.

In the above example the following assumptions are true: your source code or other used data begins at $2800 and you want to load your compressed soundtrack file somewhere between $1000 and $2800, however you may still want to execute your decrunching routine later. This will not work if you load your compressed file at $1000, because uncompressed data would begin to overwrite your loaded data shortly after you invoked decruncher routine, leading to data corruption and truly unpredictable results. What you want to do is to load your file at any address that will provide data safety. C<relocate_output_up_to> parameter ensures that.

C<relocate_output_up_to> and C<relocate_output> parameters are mutually exclusive. C<relocate_output_up_to> always takes precedence over C<relocate_output>.

=head3 precede_initial_address

C<precede_initial_address> adds given initial address at the beginning of an input stream, so this option can be used for setting up start address on the target device upon decrunching compressed data. If you are targetting a raw stream of bytes without providing initial memory address within it, decruncher routine will not be able to properly determine the right memory address, where your data should get unpacked to. Therefore it is essential to precede your input stream with the initial address, telling ByteBoozer what the target address of the uncompressed data is going to be:

    my $initial_address = 0x2000;
    crunch(source => $in, target => $out, precede_initial_address => $initial_address);

Before crunching algorithm is applied, data will be here prepended with the given initial address of $2000 first. This given initial address should be understood as the start address of the unpacked data (this is exactly where your compressed data is going to be uncrunched to).

Please note that this option and C<replace_initial_address> are mutually exclusive. This option is expected to be applied to a raw stream of bytes, while the latter one is not supposed to handle raw byte streams.

=head3 replace_initial_address

C<replace_initial_address> replaces the original initial address that is found at the beginning of an input stream with the new initial address first, even before the whole crunching process begins. This option is therefore used the same like C<precede_initial_address> for setting up a start address on the target device upon decrunching compressed data, however the initial address is not preceding the data, so that length of data remains unchanged, only its first two bytes get altered. This will tell ByteBoozer what is the new target address of the uncompressed data:

    my $initial_address = 0x4000;
    crunch(source => $in, target => $out, replace_initial_address => $initial_address);

Before crunching algorithm is applied, first two data bytes will be here replaced with the given initial address of $4000 first. This given initial address should be understood as the start address of the unpacked data (this is exactly where your compressed data is going to be uncrunched to).

Please note that this option and C<precede_initial_address> are mutually exclusive. This option is expected to be applied to a regular stream of C64 file data, while the latter one is not supposed to handle regular C64 data files.

=head3 verbose

C<verbose> indicates display of the compression result:

    my $verbose = 1;
    crunch(source => $in, target => $out, verbose => $verbose);

When set to C<1> a similar informative message will be written to the standard output: C<ByteBoozer: compressed 174 bytes into 121 bytes>.

=cut

sub _memory_address_bytes {
    my ($memory_address) = @_;
    my $memory_address_lo = chr int $memory_address % 0x100;
    my $memory_address_hi = chr int $memory_address / 0x100;
    return ($memory_address_lo, $memory_address_hi);
}

sub _read_file {
    my ($params) = @_;
    my $source = $params->{source};
    die "Error (P-1): source file IO::Handle is closed, aborting" unless $source->opened;
    $source->binmode(':bytes') if $source->can('binmode');
    my ($buffer, $data, $n, $total_size) = ('');
    while (($n = $source->sysread($data, 1)) != 0) {
        $buffer .= $data;
        $total_size++;
    }
    $params->{_source_data} = $buffer;
    return;
}

sub _crunch_data {
    my ($params) = @_;
    my $source_data = $params->{_source_data};
    my $source_size = length $source_data;
    my $source_file = bb_source($source_data, $source_size);
    my $start_address = $params->{_start_address};
    my $target_file = bb_crunch($source_file, $start_address);
    die "Error (P-2): packed file too large, aborting" unless defined $target_file;
    my $crunched_data = bb_data($target_file);
    die "Error (B-1): cannot read crunched data, aborting" unless defined $crunched_data;
    $params->{_crunched_data} = $crunched_data;
    bb_free($source_file, $target_file);
    return;
}

sub _write_file {
    my ($params) = @_;
    my $target = $params->{target};
    die "Error (P-3): target file IO::Handle is closed, aborting" unless $target->opened;
    my $crunched_data = $params->{_crunched_data};
    $target->binmode(':bytes') if $target->can('binmode');
    while (length $crunched_data > 0) {
        my $byte = substr $crunched_data, 0, 1, '';
        die "Error (P-4): cannot write undefined value, aborting" unless defined $byte;
        my $num_bytes = $target->syswrite($byte, 1);
        die "Error (B-2): cannot write output stream, aborting" if $num_bytes != 1;
    }
    unless (defined $target->flush) {
        die "Error (B-3): cannot flush output stream, aborting";
    }
    return;
}

sub _attach_decruncher {
    my ($params) = @_;
    my $start_address = $params->{attach_decruncher} || $params->{make_executable} || 0;
    $params->{_start_address} = $start_address;
    return;
}

sub _precede_initial_address {
    my ($params) = @_;
    my $precede_initial_address = $params->{precede_initial_address};
    return unless defined $precede_initial_address;
    my @memory_address = _memory_address_bytes($precede_initial_address);
    substr $params->{_source_data}, 0, 0, join '', @memory_address;
    return;
}

sub _get_address_to_relocate_output_up_to {
    my ($params) = @_;
    my $data_length = length ($params->{_crunched_data}) - 0x02;
    my $relocate_output_up_to = $params->{relocate_output_up_to};
    my $address_to_relocate_data = $relocate_output_up_to - $data_length;
    return $address_to_relocate_data;
}

sub _relocate_output {
    my ($params) = @_;
    my $relocate_output = $params->{relocate_output};
    my $relocate_output_up_to = $params->{relocate_output_up_to};
    return unless defined $relocate_output || defined $relocate_output_up_to;
    my $address_to_relocate_data =
        defined $relocate_output_up_to ? _get_address_to_relocate_output_up_to($params) : $relocate_output;
    my @memory_address = _memory_address_bytes($address_to_relocate_data);
    substr $params->{_crunched_data}, 0, 2, join '', @memory_address;
    return;
}

sub _replace_initial_address {
    my ($params) = @_;
    my $replace_initial_address = $params->{replace_initial_address};
    return unless defined $replace_initial_address;
    my @memory_address = _memory_address_bytes($replace_initial_address);
    substr $params->{_source_data}, 0, 2, join '', @memory_address;
    return;
}

sub crunch {
    my $params = { @_ };
    validate(
        @_, {
            source                  => { type => HANDLE, isa => 'IO::Handle', callbacks => {
                is_not_the_same_as_target => sub { exists $_[1]->{target} && refaddr $_[0] != refaddr $_[1]->{target} },
            } },
            target                  => { type => HANDLE, isa => 'IO::Handle', callbacks => {
                is_not_the_same_as_source => sub { exists $_[1]->{source} && refaddr $_[0] != refaddr $_[1]->{source} },
            } },
            attach_decruncher       => { type => SCALAR, optional => 1, callbacks => {
                is_valid_memory_address   => sub { looks_like_number $_[0] && $_[0] >= 0x0000 && $_[0] <= 0xffff },
            } },
            make_executable         => { type => SCALAR, optional => 1, callbacks => {
                is_valid_memory_address   => sub { looks_like_number $_[0] && $_[0] >= 0x0000 && $_[0] <= 0xffff },
            } },
            precede_initial_address => { type => SCALAR, optional => 1, callbacks => {
                is_valid_memory_address   => sub { looks_like_number $_[0] && $_[0] >= 0x0000 && $_[0] <= 0xffff },
            } },
            relocate_output         => { type => SCALAR, optional => 1, callbacks => {
                is_valid_memory_address   => sub { looks_like_number $_[0] && $_[0] >= 0x0000 && $_[0] <= 0xffff },
            } },
            relocate_output_up_to   => { type => SCALAR, optional => 1, callbacks => {
                is_valid_memory_address   => sub { looks_like_number $_[0] && $_[0] >= 0x0000 && $_[0] <= 0xffff },
            } },
            replace_initial_address => { type => SCALAR, optional => 1, callbacks => {
                is_valid_memory_address   => sub { looks_like_number $_[0] && $_[0] >= 0x0000 && $_[0] <= 0xffff },
            } },
            verbose                 => { type => SCALAR, optional => 1, regex => qr/^\d+$/ },
        }
    );
    my $pos = _seek_and_tell($params->{source}, $params->{target});
    my $source_position = $pos->{source}->{get}->($params->{source});
    my $target_position = $pos->{target}->{get}->($params->{target});
    _read_file $params;
    _precede_initial_address $params;
    die "Error (I-3): no data to crunch in input stream, aborting" unless length $params->{_source_data} > 1;
    _replace_initial_address $params;
    _attach_decruncher $params;
    _crunch_data $params;
    _relocate_output $params;
    _write_file $params;
    $pos->{source}->{set}->($params->{source}, $source_position);
    $pos->{target}->{set}->($params->{target}, $target_position);
    if (defined $params->{verbose} && $params->{verbose} == 1) {
        printf("[Archive::ByteBoozer] Compressed %u bytes into %u bytes.\n", length $params->{_source_data}, length $params->{_crunched_data});
    }
    return;
}

sub _seek_and_tell {
    my ($source, $target) = @_;
    my $source_getpos = $source->can('getpos') || \&IO::Scalar::getpos;
    my $source_setpos = $source->can('setpos') || \&IO::Scalar::setpos;
    my $target_getpos = $target->can('getpos') || \&IO::Scalar::getpos;
    my $target_setpos = $target->can('setpos') || \&IO::Scalar::setpos;
    return {
        'source' => {
            'get' => $source_getpos,
            'set' => $source_setpos,
        },
        'target' => {
            'get' => $target_getpos,
            'set' => $target_setpos,
        }
    };
}

=head1 EXAMPLES

Compress a PRG file named "part-1.prg", replace its start address with $2000 (this is where the data will be uncompressed to), move all packed bytes to $f000 (this will be written into loading address of the output file), and save crunched data into a PRG file name "part-1.crunched.prg":

  use Archive::ByteBoozer qw/crunch/;

  my $source            = new IO::File "part-1.prg", "r";
  my $target            = new IO::File "part-1.crunched.prg", "w";
  my $unpacking_address = 0x2000;
  my $relocate_address  = 0xf000;

  crunch(
    source                  => $source,
    target                  => $target,
    replace_initial_address => $unpacking_address,
    relocate_output         => $relocate_address,
  );

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

C<Archive::ByteBoozer> exports nothing by default.

You are allowed to explicitly import the crunch subroutine into the caller's namespace either by specifying its name in the import list (C<crunch>) or by using the module with the C<:crunch> tag.

=head1 SEE ALSO

L<IO::File>, L<IO::Scalar>

=head1 AUTHOR

Pawel Krol, E<lt>djgruby@gmail.comE<gt>.

=head1 VERSION

Version 0.10 (2018-11-26)

=head1 COPYRIGHT AND LICENSE

ByteBoozer cruncher/decruncher:

Copyright (C) 2004-2006, 2008-2009, 2012 David Malmborg.

Archive::ByteBoozer Perl interface:

Copyright (C) 2012-2013, 2016, 2018 by Pawel Krol.

This library is free open source software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.6 or, at your option, any later version of Perl 5 you may have available.

PLEASE NOTE THAT IT COMES WITHOUT A WARRANTY OF ANY KIND!

=cut

1;
