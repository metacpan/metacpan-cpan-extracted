package CPU::Z80::Disassembler::Memory;

#------------------------------------------------------------------------------

=head1 NAME

CPU::Z80::Disassembler::Memory - Memory representation for Z80 disassembler

=cut

#------------------------------------------------------------------------------

use strict;
use warnings;

use Carp; our @CARP_NOT;		# do not report errors in this package
use File::Slurp;
use Bit::Vector;

use CPU::Z80::Disassembler::Format;

our $VERSION = '0.07';

#------------------------------------------------------------------------------

=head1 SYNOPSIS

  use CPU::Z80::Disassembler::Memory;
  $mem = CPU::Z80::Disassembler::Memory->new;
  
  $mem->load_file($file_name, $addr, $opt_skip_bytes, $opt_length);
  $it = $mem->loaded_iter(); while (($min,$max) = $it->()) {}
  
  $byte = $mem->peek8u($addr); $byte = $mem->peek($addr);
  $byte = $mem->peek8s($addr);
  
  $word = $mem->peek16u($addr);
  $word = $mem->peek16s($addr);
  
  $str = $mem->peek_str( $addr, $length);
  $str = $mem->peek_strz($addr);
  $str = $mem->peek_str7($addr);
  
  $mem->poke8u($addr, $byte); $mem->poke($addr, $byte);
  $mem->poke8s($addr, $byte);
  
  $mem->poke16u($addr, $word);
  $mem->poke16s($addr, $word);
  
  $mem->poke_str( $addr, $str);
  $mem->poke_strz($addr, $str);
  $mem->poke_str7($addr, $str);

=head1 DESCRIPTION

This module represents a memory segment being diassembled. 

=head1 FUNCTIONS

=head2 new

Creates a new empty object.

=cut

#------------------------------------------------------------------------------
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(
		'_mem',			# string of 64 Kbytes
		'_loaded',		# Bit::Vector, one bit per address, 1 if byte loaded
);

sub new {
	my($class) = @_;
	my $loaded = Bit::Vector->new(0x10000);
	my $mem = "\0" x $loaded->Size;
	return bless { _mem => $mem, _loaded => $loaded }, $class;
}

#------------------------------------------------------------------------------
# check ranges

sub _check_addr {
	my($self, $addr) = @_;
	croak("address ".format_hex($addr)." out of range") 
		if ($addr < 0 || $addr >= $self->_loaded->Size);
}

sub _check_value8u {
	my($self, $byte) = @_;
	croak("unsigned byte ".format_hex($byte)." out of range") 
		if ($byte < 0 || $byte > 0xFF);
}

sub _check_value8s {
	my($self, $byte) = @_;
	croak("signed byte ".format_hex($byte)." out of range") 
		if ($byte < -0x80 || $byte > 0x7F);
}

sub _check_value16u {
	my($self, $word) = @_;
	croak("unsigned word ".format_hex($word)." out of range") 
		if ($word < 0 || $word > 0xFFFF);
}

sub _check_value16s {
	my($self, $word) = @_;
	croak("signed word ".format_hex($word)." out of range") 
		if ($word < -0x8000 || $word > 0x7FFF);
}

sub _check_strz {
	my($self, $str) = @_;
	croak("invalid zero character in string") 
		if $str =~ /\0/;
}

sub _check_str7 {
	my($self, $str) = @_;
	croak("invalid empty string") if length($str) < 1;
	croak("invalid bit-7 set character in string") 
		if $str =~ /[\x80-\xFF]/;
}

#------------------------------------------------------------------------------

=head2 load_file

Loads a binary file to the memory. 
The argument C<$addr> indicates where in the memory to load the file, and defaults to 0.
The argument C<$opt_skip_bytes> indicates how many bytes to skip from the start 
of the binary file and defaults to 0. 
This is useful to read C<.SNA> ZX Spectrum Snapshot Files which have a header of 27 bytes.
The argument C<$opt_length> limits the number of bytes to read to memory and
defaults to all the file after the header.

=cut

#------------------------------------------------------------------------------
sub load_file {
	my($self, $file_name, $addr, $opt_skip_bytes, $opt_length) = @_;
	
	my $bytes = read_file($file_name, binmode => ':raw');
	$addr			||= 0;
	$opt_skip_bytes ||= 0;
	$opt_length		||= length($bytes) - $opt_skip_bytes;
	
	$self->poke_str($addr, substr($bytes, $opt_skip_bytes, $opt_length));
}
#------------------------------------------------------------------------------

=head2 loaded_iter

Returns an iterator to return each block of consecutive loaded addresses. 
C<$min> is the first address of the consecutive block, C<$max> is last address
of the block.

=cut

#------------------------------------------------------------------------------
sub loaded_iter {
	my($self) = @_;
	my $loaded = $self->_loaded;
	my $start = 0;
	
	return sub {
		while ( $start < $loaded->Size &&
				(my($min,$max) = $loaded->Interval_Scan_inc($start)) ) {
			$start = $max + 2;	# start after the 0 after $max
			return ($min, $max);
		}
		return ();		# no more blocks
    };
}
#------------------------------------------------------------------------------

=head2 peek, peek8u

Retrieves the byte (0 .. 255) from the given address. 
Returns C<undef> if the memory at that address was not loaded.

=cut

#------------------------------------------------------------------------------
sub peek8u {
	my($self, $addr) = @_;
	$self->_check_addr($addr);
	return $self->_loaded->bit_test($addr) ?
				ord(substr($self->{_mem}, $addr, 1)) :
				undef;
}
sub peek { goto &peek8u }
#------------------------------------------------------------------------------

=head2 peek8s

Same as C<peek8u>, but treats byte as signed (-128 .. 127).

=cut

#------------------------------------------------------------------------------
sub peek8s {
	my($self, $addr) = @_;
	my $byte = $self->peek8u($addr);
	return undef unless defined $byte;
	$byte -= 0x100 if $byte & 0x80;
	return $byte;
}
#------------------------------------------------------------------------------

=head2 peek16u

Retrieves the two-byte word (0 .. 65535) from the given address, least 
significant first (little-endian).
Returns C<undef> if the memory at any of the two addresses was not loaded.

=cut

#------------------------------------------------------------------------------
sub peek16u {
	my($self, $addr) = @_;
	my $lo = $self->peek($addr++); return undef unless defined $lo;
	my $hi = $self->peek($addr++); return undef unless defined $hi;
	return ($hi << 8) | $lo;
}
#------------------------------------------------------------------------------

=head2 peek16s

Same as C<peek16u>, but treats word as signed (-32768 .. 32767).

=cut

#------------------------------------------------------------------------------
sub peek16s {
	my($self, $addr) = @_;
	my $word = $self->peek16u($addr);
	return undef unless defined $word;
	$word -= 0x10000 if $word & 0x8000;
	return $word;
}
#------------------------------------------------------------------------------

=head2 peek_str

Retrieves a string from the given address with the given length.
Returns C<undef> if the memory at any of the addresses was not loaded.

=cut

#------------------------------------------------------------------------------
sub peek_str {
	my($self, $addr, $length) = @_;
	croak("invalid length $length") if $length < 1;
	my $str = "";
	while ($length-- > 0) {
		my $byte = $self->peek8u($addr++);
		return undef unless defined $byte;
		$str .= chr($byte);
	}
	return $str;
}
#------------------------------------------------------------------------------

=head2 peek_strz

Retrieves a zero-terminated string from the given address. The returned string
does not include the final zero byte.
Returns C<undef> if the memory at any of the addresses was not loaded.

=cut

#------------------------------------------------------------------------------
sub peek_strz {
	my($self, $addr) = @_;
	my $str = "";
	while (1) {
		my $byte = $self->peek8u($addr++);
		return undef unless defined $byte;
		return $str if $byte == 0;
		$str .= chr($byte);
	}
}
#------------------------------------------------------------------------------

=head2 peek_str7

Retrieves a bit-7-set-terminated string from the given address. 
This string has all characters with bit 7 reset, execept the last character, 
where bit 7 is set. The returned string has bit 7 reset in all characters.
Returns C<undef> if the memory at any of the addresses was not loaded.

=cut

#------------------------------------------------------------------------------
sub peek_str7 {
	my($self, $addr) = @_;
	my $str = "";
	while (1) {
		my $byte = $self->peek8u($addr++);
		return undef unless defined $byte;
		$str .= chr($byte & 0x7F);		# clear bit 7
		return $str if $byte & 0x80;	# bit 7 set
	}
}
#------------------------------------------------------------------------------

=head2 poke, poke8u

Stores the unsigned byte (0 .. 255) at the given address, 
and signals that the address was loaded.

=cut

#------------------------------------------------------------------------------
sub poke8u {
	my($self, $addr, $byte) = @_;
	$self->_check_addr($addr);
	$self->_check_value8u($byte);
	substr($self->{_mem}, $addr, 1) = chr($byte);
	$self->_loaded->Bit_On($addr);
}
sub poke { goto &poke8u }
#------------------------------------------------------------------------------

=head2 poke8s

Same as C<poke8u>, but treats byte as signed (-128 .. 127).

=cut

#------------------------------------------------------------------------------
sub poke8s {
	my($self, $addr, $byte) = @_;
	$self->_check_value8s($byte);
	$self->poke8u($addr, $byte & 0xFF);
}
#------------------------------------------------------------------------------

=head2 poke16u

Stores the two-byte word (0 .. 65535) at the given address, least 
significant first (little-endian), 
and signals that the address was loaded.

=cut

#------------------------------------------------------------------------------
sub poke16u {
	my($self, $addr, $word) = @_;
	$self->_check_addr($addr);
	$self->_check_value16u($word);
	$self->poke8u($addr++, $word & 0xFF);
	$self->poke8u($addr++, ($word >> 8) & 0xFF);
}
#------------------------------------------------------------------------------

=head2 poke16s

Same as C<poke16u>, but treats word as signed (-32768 .. 32767).

=cut

#------------------------------------------------------------------------------
sub poke16s {
	my($self, $addr, $word) = @_;
	$self->_check_value16s($word);
	$self->poke16u($addr, $word & 0xFFFF);
}
#------------------------------------------------------------------------------

=head2 poke_str

Stores the string at the given start address, 
and signals that the addresser were loaded.

=cut

#------------------------------------------------------------------------------
sub poke_str {
	my($self, $addr, $str) = @_;
	$self->_check_addr($addr);

	if (length($str) > 0) {
		my $end_addr = $addr + length($str) - 1;
		$self->_check_addr($end_addr);
	
		substr($self->{_mem}, $addr, length($str)) = $str;
		$self->_loaded->Interval_Fill($addr, $end_addr);
	}
}
#------------------------------------------------------------------------------

=head2 poke_strz

Stores the string at the given start address, and adds a zero byte, 
and signals that the addresses were loaded.

=cut

#------------------------------------------------------------------------------
sub poke_strz {
	my($self, $addr, $str) = @_;
	$self->_check_strz($str);
	$self->poke_str($addr, $str.chr(0));
}
#------------------------------------------------------------------------------

=head2 poke_str7

Stores the string at the given start address and sets the bit 7 of the
last character, 
and signals that the addresses were loaded.

=cut

#------------------------------------------------------------------------------
sub poke_str7 {
	my($self, $addr, $str) = @_;
	$self->_check_str7($str);
	substr($str, -1, 1) = chr(ord(substr($str, -1, 1)) | 0x80);		# set bit 7
	$self->poke_str($addr, $str);
}
#------------------------------------------------------------------------------

=head1 AUTHOR, BUGS, FEEDBACK, LICENSE AND COPYRIGHT

See L<CPU::Z80::Disassembler|CPU::Z80::Disassembler>.

=cut

#------------------------------------------------------------------------------

1;
