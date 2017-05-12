package D64::File::PRG;

=head1 NAME

D64::File::PRG - Handling individual C64's PRG files

=head1 SYNOPSIS

  use D64::File::PRG;

  my $prg = D64::File::PRG->new('FILE' => $file);
  my $prg = D64::File::PRG->new('RAW_DATA' => \$data, 'LOADING_ADDRESS' => 0x0801);

  $prg->change_loading_address('LOADING_ADDRESS' => 0x6400);

  my $data = $prg->get_data();
  my $data = $prg->get_data('FORMAT' => 'ASM', 'ROW_LENGTH' => 10);

  $prg->set_data('RAW_DATA' => \$data, 'LOADING_ADDRESS' => 0x1000);
  $prg->set_data('RAW_DATA' => \$data);
  $prg->set_file_data('FILE_DATA' => \$file_data);

  $prg->write_file('FILE' => $file);

=head1 DESCRIPTION

D64::File::PRG is a Perl module providing the set of methods for handling individual C64's PRG files. It enables an easy access to the raw contents of any PRG file, manipulation of its loading address, and transforming binary data into assembly code understood by tools like "Dreamass" or "Turbo Assembler".

=head1 METHODS

=cut

use bytes;
use strict;
use warnings;

use Carp;
use Exporter;
use IO::Scalar;
use Scalar::Util qw(looks_like_number);

our $VERSION     = '0.03';
our @ISA         = qw(Exporter);
our @EXPORT      = ();
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (default => [qw()]);

local $| = 1;

=head2 new

A new D64::File::PRG object instance is created either by providing the path to an existing file, which is then being read into a memory, or by providing a scalar reference to the raw binary data with an accompanying loading address. This is illustrated by the following examples:

  my $prg = D64::File::PRG->new('FILE' => $file);
  my $prg = D64::File::PRG->new('RAW_DATA' => \$data, 'LOADING_ADDRESS' => 0x0801);

Constructor will die upon one of the following conditions:

  1. File size is less than two bytes.
  2. Loading address provided is outside of a 16-bit range.
  3. Any character within a raw data is not a single byte.

There is an additional optional boolean "VERBOSE" available (defaulting to 0), which indicates that the extensive debugging messages should be printed out to the standard output. By default module acts silently, reporting error messages only.

=cut

sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
    my $self  = {};
    bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
    my $self            = shift;
    my $params          = {@_};
    my $verbose         = $params->{'VERBOSE'};         # display diagnostic messages
    my $file            = $params->{'FILE'};            # get data from file
    my $loading_address = $params->{'LOADING_ADDRESS'}; # externally provided loading address
    my $raw_data_ref    = $params->{'RAW_DATA'};        # externally provided raw data
    my ($package) = (caller(0))[0];
    $self->{'VERBOSE'} = $verbose;
    $self->_verbose_message('MESSAGE' => "Initializing new \"${package}\" object instance", 'ERROR' => 0) if $verbose;
    # When "FILE" parameter is defined, it takes the precedence over "LOAD/DATA" parameters:
    if (defined $file) {
        $self->read_file('FILE' => $file);
    }
    else {
        # LOADING_ADDRESS: loading address (must be a valid value)
        unless (defined $loading_address) {
            $self->_verbose_message('MESSAGE' => "an undefined loading address has been provided to the constructor", 'ERROR' => 1);
        }
        $self->_get_loading_address_from_scalar('LOADING_ADDRESS' => $loading_address, 'VERBOSE' => $verbose);
        # RAW_DATA: binary data provided as a raw data scalar
        $self->_get_raw_contents_from_scalarref('RAW_DATA' => $raw_data_ref, 'VERBOSE' => $verbose);
    }
    $self->_verbose_message('MESSAGE' => "Returning new object instance upon successful init", 'ERROR' => 0) if $verbose;
    return;
}

sub _get_loading_address_from_scalar {
    my $self            = shift;
    my $params          = {@_};
    my $loading_address = $params->{'LOADING_ADDRESS'}; # externally provided loading address
    my $verbose         = $params->{'VERBOSE'};         # display diagnostic messages
    unless (looks_like_number $loading_address) {
        $self->_verbose_message('MESSAGE' => "a non-numeric scalar value cannot be converted into loading address", 'ERROR' => 1);
    }
    my $loading_address_readable = uc sprintf "\$%04x", $loading_address;
    $self->_verbose_message('MESSAGE' => "Validating value of provided loading address: ${loading_address_readable}", 'ERROR' => 0) if $verbose;
    if ($loading_address < 0x0000 or $loading_address > 0xffff) {
        $self->_verbose_message('MESSAGE' => "invalid loading address provided (${loading_address_readable})", 'ERROR' => 1);
    }
    $self->_verbose_message('MESSAGE' => "Received the correct file loading address: ${loading_address_readable}", 'ERROR' => 0) if $verbose;
    $self->{'LOADING_ADDRESS'} = $loading_address;
}

=head2 read_file

While operating an existing D64::File::PRG object instance, there is no need to create a new one when you simply want to replace it with the contents of another file, that is if you only want to load a new data (however you need to create a new object instance if you want to provide raw data through a scalar reference - this limitation should be patched with the next release of this module). The example follows:

  $prg->read_file('FILE' => $file);

=cut

sub read_file {
    my $self    = shift;
    my $params  = {@_};
    my $file    = $params->{'FILE'};  # get data from file
    my $verbose = $self->{'VERBOSE'}; # display diagnostic messages
    # Verify if file exists:
    unless (-e $file) {
        $self->_verbose_message('MESSAGE' => "file \"${file}\" does not exist", 'ERROR' => 1);
    }
    $self->{'FILENAME'} = $file;
    # Read data from file:
    $self->_verbose_message('MESSAGE' => "Opening file \"${file}\" for reading", 'ERROR' => 0) if $verbose;
    open my $fh, '<', $file or $self->_verbose_message('MESSAGE' => "could not open filehandle for \"${file}\" file", 'ERROR' => 1);
    binmode $fh, ':bytes';
    $self->_read_file('FILEHANDLE' => $fh, 'VERBOSE' => $verbose);
    close $fh or $self->_verbose_message('MESSAGE' => "could not close opened filehandle for \"${file}\" file", 'ERROR' => 1);
    $self->_verbose_message('MESSAGE' => "Closing file \"${file}\" upon successful read", 'ERROR' => 0) if $verbose;
}

sub _read_file {
    my ($self, %params) = @_;

    my $fh      = $params{FILEHANDLE};
    my $verbose = $params{VERBOSE};

    $self->_get_loading_address_from_file(FILEHANDLE => $fh, VERBOSE => $verbose);
    $self->_get_raw_contents_from_file(FILEHANDLE => $fh, VERBOSE => $verbose);

    return;
}

sub _get_raw_contents_from_scalarref {
    my $self         = shift;
    my $params       = {@_};
    my $raw_data_ref = $params->{'RAW_DATA'}; # externally provided raw data
    my $verbose      = $params->{'VERBOSE'};  # display diagnostic messages
    unless (ref $raw_data_ref eq 'SCALAR') {
        my $raw_data_reftype = ref ($raw_data_ref) ? ( ref ($raw_data_ref) . ' reference' ) : 'SCALAR itself';
        $self->_verbose_message('MESSAGE' => "raw data has to be a SCALAR reference (but is a ${raw_data_reftype})", 'ERROR' => 1);
    }
    $self->{'RAW_DATA'} = []; # empty all previously stored raw file contents
    my ($bytes_count, $byte) = (0);
    $self->_verbose_message('MESSAGE' => "Retrieving raw file contents from a SCALAR reference", 'ERROR' => 0) if $verbose;
    my $raw_data_length = length ${$raw_data_ref};
    while ($bytes_count < $raw_data_length) {
        my $byte = substr ${$raw_data_ref}, $bytes_count, 1;
        my $byte_value = ord $byte; # get byte numeric value
        if ($byte_value < 0x00 or $byte_value > 0xff) {
            my $byte_value_readable = sprintf "\$%02x", $byte_value;
            $self->_verbose_message('MESSAGE' => "invalid byte value (${byte_value_readable}) in raw data at offset ${bytes_count}", 'ERROR' => 1);
        }
        push @{$self->{'RAW_DATA'}}, $byte_value;
        $bytes_count++;
    }
    $self->_verbose_message('MESSAGE' => "Received ${bytes_count} bytes of the raw file contents", 'ERROR' => 0) if $verbose;
}

sub _get_raw_contents_from_file {
    my $self    = shift;
    my $params  = {@_};
    my $fh      = $params->{'FILEHANDLE'}; # already opened filehandle
    my $verbose = $params->{'VERBOSE'};    # display diagnostic messages
    my $file    = $self->{'FILENAME'};     # filename associated with "$fh" filehandle
    my ($bytes_count, $byte) = (0);
    $self->{'RAW_DATA'} = []; # empty all previously stored raw file contents
    $self->_verbose_message('MESSAGE' => "Retrieving raw file contents from an opened filehandle", 'ERROR' => 0) if $verbose;
    while ( sysread $fh, $byte, 1 ) {
        $bytes_count++;
        push @{$self->{'RAW_DATA'}}, ord $byte; # get byte numeric value
    }
    $self->_verbose_message('MESSAGE' => "Received ${bytes_count} bytes of the raw file contents", 'ERROR' => 0) if $verbose;
}

sub _get_loading_address_from_file {
    my $self    = shift;
    my $params  = {@_};
    my $fh      = $params->{'FILEHANDLE'}; # already opened filehandle
    my $verbose = $params->{'VERBOSE'};    # display diagnostic messages
    my $file    = $self->{'FILENAME'};     # filename associated with "$fh" filehandle
    my ($load_addr_lo, $load_addr_hi, $bytes_count);
    $self->_verbose_message('MESSAGE' => "Retrieving loading address from an opened filehandle", 'ERROR' => 0) if $verbose;
    $bytes_count = sysread $fh, $load_addr_lo, 1;
    my $filename = defined $file ? qq{"${file}"} : q{IO::Scalar};
    if ($bytes_count != 1) {
        $self->_verbose_message('MESSAGE' => "unexpected end of file while reading loading address from $filename filehandle", 'ERROR' => 1);
    }
    $bytes_count = sysread $fh, $load_addr_hi, 1;
    if ($bytes_count != 1) {
        $self->_verbose_message('MESSAGE' => "unexpected end of file while reading loading address from $filename filehandle", 'ERROR' => 1);
    }
    my $loading_address = ord ($load_addr_lo) + 0x100 * ord ($load_addr_hi);
    my $loading_address_readable = uc sprintf "\$%04x", $loading_address;
    $self->_verbose_message('MESSAGE' => "Received the correct file loading address: ${loading_address_readable}", 'ERROR' => 0) if $verbose;
    $self->{'LOADING_ADDRESS'} = $loading_address;
}

=head2 get_data

All raw data can be accessed through this method. You might explicitly want to request the format of a data retrieved. By default the raw content is collected unless you otherwise specify to get an assembly formatted source code. In both cases a scalar value is returned. In the latter case you are able to provide an additional parameter indicating how many byte values will be returned on a single line (these are 8 bytes by default). Here are a couple of examples:

  my $raw_data = $prg->get_data('FORMAT' => 'RAW', 'LOAD_ADDR_INCL' => 0);
  my $asm_data = $prg->get_data('FORMAT' => 'ASM', 'LOAD_ADDR_INCL' => 1, 'ROW_LENGTH' => 4);

There is an additional optional boolean "LOAD_ADDR_INCL", which indicates if a loading address should be included in the output string. For raw contents it defaults to 0, while for assembly source code format it defaults to 1. This is reasonable, as you usually don't want loading address included in a raw data, but it becomes quite useful when compiling a source code.

=cut

sub get_data {
    my $self    = shift;
    my $params  = {@_};
    my $verbose = $self->{'VERBOSE'};
    my $format  = $params->{'FORMAT'}; # format of data returned from this method (defaults to "RAW")
    $format = 'RAW' unless defined $format;
    # LOAD_ADDR_INCL: a boolean indicating if loading address should be included to output
    # It defaults to 0 for RAW format, and to 1 for ASM format
    my $loading_address_included = $params->{'LOAD_ADDR_INCL'};
    if ($format eq 'RAW') {
        $self->_verbose_message('MESSAGE' => "Getting raw data contents into a scalar value", 'ERROR' => 0) if $verbose;
        my $data = ''; # prepare scalar value with the whole RAW contents
        $self->_add_loading_address_to_scalarref('RAW_DATA' => \$data, 'VERBOSE' => $verbose) if $loading_address_included;
        $self->_add_raw_data_to_scalarref('RAW_DATA' => \$data, 'VERBOSE' => $verbose);
        return $data;
    } elsif ($format eq 'ASM') {
        $loading_address_included = 1 unless defined $loading_address_included;
        $self->_verbose_message('MESSAGE' => "Getting raw data composed as an assembly source code", 'ERROR' => 0) if $verbose;
        my $row_length = $params->{'ROW_LENGTH'} || 8;
        if ($row_length !~ m/^\d+$/ or $row_length < 0x01 or $row_length > 0xff) {
            $self->_verbose_message('MESSAGE' => "invalid row length (\"${row_length}\") request for assembly raw data composition", 'ERROR' => 1);
        }
        my $data = ''; # prepare scalar value with the whole ASSEMBLY contents
        if ($loading_address_included) {
            $self->_compose_comment_line_to_scalarref('RAW_DATA' => \$data, 'ROW_LENGTH' => $row_length, 'VERBOSE' => $verbose);
            $self->_compose_loading_address_to_scalarref('RAW_DATA' => \$data, 'VERBOSE' => $verbose);
        }
        $self->_compose_comment_line_to_scalarref('RAW_DATA' => \$data, 'ROW_LENGTH' => $row_length, 'VERBOSE' => $verbose);
        $self->_compose_raw_data_to_scalarref('RAW_DATA' => \$data, 'ROW_LENGTH' => $row_length, 'VERBOSE' => $verbose);
        $self->_compose_comment_line_to_scalarref('RAW_DATA' => \$data, 'ROW_LENGTH' => $row_length, 'VERBOSE' => $verbose);
        return $data;
    }
    else {
        $self->_verbose_message('MESSAGE' => "unrecognized data format (\"${format}\")", 'ERROR' => 1);
    }
}

sub _compose_comment_line_to_scalarref {
    my $self       = shift;
    my $params     = {@_};
    my $data_ref   = $params->{'RAW_DATA'};   # scalar value with the whole RAW contents
    my $row_length = $params->{'ROW_LENGTH'}; # number of byte values per single line
    my $verbose    = $params->{'VERBOSE'};    # display diagnostic messages
    ${$data_ref} .= ';' . '-' x (19 + 5 * $row_length) . "\n";
}

sub _compose_raw_data_to_scalarref {
    my $self       = shift;
    my $params     = {@_};
    my $data_ref   = $params->{'RAW_DATA'};   # scalar value with the whole RAW contents
    my $row_length = $params->{'ROW_LENGTH'}; # number of byte values per single line
    my $verbose    = $params->{'VERBOSE'};    # display diagnostic messages
    my $line;
    my $offset = 0;
    foreach my $byte (@{$self->{'RAW_DATA'}}) {
        if ($offset % $row_length == 0) {
            if ($offset != 0) {
                $line =~ s/, $//;
                ${$data_ref} .= "${line}\n";
            }
            $line = ' ' x 16 . '.byte ';
        }
        my $byte_value = sprintf "\$%02x, ", $byte;
        $line .= $byte_value;
        $offset++;
    }
    ${$data_ref} .= "${line}\n" if $line =~ m/, $/i;
    ${$data_ref} =~ s/, $//;
}

sub _add_raw_data_to_scalarref {
    my $self     = shift;
    my $params   = {@_};
    my $data_ref = $params->{'RAW_DATA'}; # scalar value with the whole RAW contents
    my $verbose  = $params->{'VERBOSE'};  # display diagnostic messages
    foreach my $byte (@{$self->{'RAW_DATA'}}) {
        my $raw_byte = chr $byte;
        ${$data_ref} .= $raw_byte;
    }
}

sub _compose_loading_address_to_scalarref {
    my $self     = shift;
    my $params   = {@_};
    my $data_ref = $params->{'RAW_DATA'}; # scalar value with the whole RAW contents
    my $verbose  = $params->{'VERBOSE'};  # display diagnostic messages
    my $loading_address = sprintf "%04x", hex $self->{'LOADING_ADDRESS'};
    ${$data_ref} .= ' ' x 16;
    ${$data_ref} .= sprintf "*= \$%04x\n", $loading_address;
}

sub _add_loading_address_to_scalarref {
    my $self     = shift;
    my $params   = {@_};
    my $data_ref = $params->{'RAW_DATA'}; # scalar value with the whole RAW contents
    my $verbose  = $params->{'VERBOSE'};  # display diagnostic messages
    my $loading_address = sprintf "%04x", $self->{'LOADING_ADDRESS'};
    my ($addr_hi, $addr_lo) = ( $loading_address =~ m/([0-9a-f]{2})/ig );
    ${$data_ref} .= chr (hex $addr_lo);
    ${$data_ref} .= chr (hex $addr_hi);
}

=head2 change_loading_address

You can modify original file loading address by performing the following operation:

  $prg->change_loading_address('LOADING_ADDRESS' => 0x6400);

=cut

sub change_loading_address {
    my $self            = shift;
    my $params          = {@_};
    my $loading_address = $params->{'LOADING_ADDRESS'}; # new loading address
    my $verbose         = $self->{'VERBOSE'};           # display diagnostic messages
    # Verify if provided loading address is correct:
    unless (defined $loading_address) {
        $self->_verbose_message('MESSAGE' => "an undefined loading address has been provided to the method that was supposed to change its value", 'ERROR' => 1);
    }
    # Update loading address if correct value provided:
    $self->_get_loading_address_from_scalar('LOADING_ADDRESS' => $loading_address, 'VERBOSE' => $verbose);
    $self->_verbose_message('MESSAGE' => "File loading address has been succesfully updated", 'ERROR' => 0) if $verbose;
}

=head2 set_data

You can update raw program data and its loading address by performing the following operation:

  $prg->set_data('RAW_DATA' => \$data, 'LOADING_ADDRESS' => 0x1000);

You can update raw program data without modifying its loading address by performing the following operation:

  $prg->set_data('RAW_DATA' => \$data);

=cut

sub set_data {
    my ($self, %params) = @_;

    $self->_get_raw_contents_from_scalarref(%params);
    $self->change_loading_address(%params) if exists $params{LOADING_ADDRESS};

    return;
}

=head2 set_file_data

You can replace original program data assuming that its loading address is included within the first two bytes of provided file data by performing the following operation:

  $prg->set_file_data('FILE_DATA' => \$file_data);

=cut

sub set_file_data {
    my ($self, %params) = @_;

    my $file_data = $params{FILE_DATA};
    my $verbose   = $params{VERBOSE};

    my $fh = new IO::Scalar $file_data;
    $self->_read_file(FILEHANDLE => $fh, VERBOSE => $verbose);
    $fh->close;

    return;
}

=head2 write_file

There is a command allowing you to save the whole contents into a disk file:

  $prg->write_file('FILE' => $file, 'OVERWRITE' => 1);

Note that when you specify any value evaluating to true for 'OVERWRITE' parameter, any existing file will be replaced (overwriting is disabled by default).

=cut

sub write_file {
    my $self      = shift;
    my $params    = {@_};
    my $file      = $params->{'FILE'};      # write data to file
    my $overwrite = $params->{'OVERWRITE'}; # a boolean indicating if any existing file should be overwritten (no files will be overwritten by default)
    my $verbose   = $self->{'VERBOSE'};     # display diagnostic messages
    $self->{'TARGET_FILENAME'} = $file;
    # Write data to file:
    $self->_verbose_message('MESSAGE' => "Opening file \"${file}\" for writing", 'ERROR' => 0) if $verbose;
    # Verify if file exists:
    if (-e $file) {
        unless ($overwrite) {
            $self->_verbose_message('MESSAGE' => "file \"${file}\" already exists", 'ERROR' => 1);
        }
        else {
            $self->_verbose_message('MESSAGE' => "File exists (overwriting the existing content)", 'ERROR' => 0) if $verbose;
        }
    }
    open my $fh, '>', $file or $self->_verbose_message('MESSAGE' => "could not open filehandle for \"${file}\" file", 'ERROR' => 1);
    binmode $fh, ':bytes';
    $self->_write_loading_address_to_file('FILEHANDLE' => $fh, 'VERBOSE' => $verbose);
    $self->_write_raw_contents_to_file('FILEHANDLE' => $fh, 'VERBOSE' => $verbose);
    close $fh or $self->_verbose_message('MESSAGE' => "could not close opened filehandle for \"${file}\" file", 'ERROR' => 1);
    $self->_verbose_message('MESSAGE' => "Closing file \"${file}\" upon successful write", 'ERROR' => 0) if $verbose;
}

sub _write_raw_contents_to_file {
    my $self    = shift;
    my $params  = {@_};
    my $fh      = $params->{'FILEHANDLE'}; # already opened filehandle
    my $verbose = $params->{'VERBOSE'};    # display diagnostic messages
    my $file    = $self->{'TARGET_FILENAME'}; # filename associated with "$fh" filehandle
    my ($bytes_count, $byte) = (0);
    $self->_verbose_message('MESSAGE' => "Writing raw file contents into an opened filehandle", 'ERROR' => 0) if $verbose;
    foreach my $byte (@{$self->{'RAW_DATA'}}) {
        my $bytes_written = syswrite $fh, chr (hex $byte), 1;
        if ($bytes_written != 1) {
            $self->_verbose_message('MESSAGE' => "unexpected difficulties writing raw file contents to \"${file}\" filehandle at offset ${bytes_count} ($!)", 'ERROR' => 1);
        }
        $bytes_count++;
    }
    $self->_verbose_message('MESSAGE' => "Written ${bytes_count} bytes of the raw file contents", 'ERROR' => 0) if $verbose;
}

sub _write_loading_address_to_file {
    my $self    = shift;
    my $params  = {@_};
    my $fh      = $params->{'FILEHANDLE'}; # already opened filehandle
    my $verbose = $params->{'VERBOSE'};    # display diagnostic messages
    my $file    = $self->{'TARGET_FILENAME'}; # filename associated with "$fh" filehandle
    my $loading_address = sprintf "%04x", $self->{'LOADING_ADDRESS'};
    my ($addr_hi, $addr_lo) = ( $loading_address =~ m/([0-9a-f]{2})/ig );
    my $bytes_count;
    $self->_verbose_message('MESSAGE' => "Writing loading address into an opened filehandle", 'ERROR' => 0) if $verbose;
    $bytes_count = syswrite $fh, chr (hex $addr_lo), 1;
    if ($bytes_count != 1) {
        $self->_verbose_message('MESSAGE' => "unexpected difficulties writing loading address to \"${file}\" filehandle ($!)", 'ERROR' => 1);
    }
    $bytes_count = syswrite $fh, chr (hex $addr_hi), 1;
    if ($bytes_count != 1) {
        $self->_verbose_message('MESSAGE' => "unexpected difficulties writing loading address to \"${file}\" filehandle ($!)", 'ERROR' => 1);
    }
    my $loading_address_readable = uc sprintf "\$%04x", $self->{'LOADING_ADDRESS'};
    $self->_verbose_message('MESSAGE' => "Written the following file loading address: ${loading_address_readable}", 'ERROR' => 0) if $verbose;
}

sub _verbose_message {
    my $self    = shift;
    my $params  = {@_};
    my $message = $params->{'MESSAGE'};
    my $error   = $params->{'ERROR'};
    my ($package, $line, $subroutine) = (caller(1))[0,2,3];
    ($package, $line, $subroutine) = (caller(0))[0,2,3] if $package eq 'main';
    if ($error) {
        croak "[${package}][ERROR] ${subroutine} subroutine error at line ${line}: ${message}";
    }
    else {
        print "[${package}][INFO] ${message}\n";
    }
}

=head1 EXAMPLES

Retrieving raw data as an assembly formatted source code can be expressed using the following few lines of Perl code:

  use D64::File::PRG;
  my $data = join ('', map {chr} (1,2,3,4,5));
  my $prg  = D64::File::PRG->new('RAW_DATA' => \$data, 'LOADING_ADDRESS' => 0x0801);
  my $src  = $prg->get_data('FORMAT' => 'ASM', 'ROW_LENGTH' => 4);
  print $src;

When executed, it prints out the source code that is ready for compilation:

  ;---------------------------------------
                  *= $0801
  ;---------------------------------------
                  .byte $01, $02, $03, $04
                  .byte $05
  ;---------------------------------------

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

None. No method is exported into the caller's namespace either by default or explicitly.

=head1 SEE ALSO

I am working on the set of modules providing an easy way to access and manipulate the contents of D64 disk images and T64 tape images. D64::File::PRG is the first module of this set, as it provides operations necessary for handling individual C64's PRG files, which are the smallest building blocks for those images. Upon completion I am going to successively upload all my new modules into the CPAN.

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.03 (2013-01-19)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2013 by Pawel Krol.

This library is free open source software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.6 or, at your option, any later version of Perl 5 you may have available.

PLEASE NOTE THAT IT COMES WITHOUT A WARRANTY OF ANY KIND!

=cut

1;
