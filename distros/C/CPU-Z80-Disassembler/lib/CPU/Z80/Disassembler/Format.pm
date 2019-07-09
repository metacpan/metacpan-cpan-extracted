package CPU::Z80::Disassembler::Format;

#------------------------------------------------------------------------------

=head1 NAME

CPU::Z80::Disassembler::Format - Format output of disassembler

=cut

#------------------------------------------------------------------------------

use strict;
use warnings;

our $VERSION = '0.07';

#------------------------------------------------------------------------------

=head1 SYNOPSYS

  use CPU::Z80::Disassembler::Format;
  print format_hex($x), format_hex2($x), format_hex4($x); format_bin8($x);
  print format_dis($x), format_str($x);

=head1 DESCRIPTION

Exports functions to format output values in the disassembler listing.

=head1 EXPORTS

Exports all functions by default.

=head1 FUNCTIONS

=cut
#------------------------------------------------------------------------------
use Exporter 'import';
our @EXPORT = qw( format_hex format_hex2 format_hex4 
				  format_bin8
				  format_dis format_str );
#------------------------------------------------------------------------------

=head2 format_hex

Returns the string representation of a value in hexadecimal..

=cut

#------------------------------------------------------------------------------
sub format_hex { 
	$_[0] < 0 ? sprintf("-\$%02X", -$_[0]) : sprintf("\$%02X", $_[0]);
}
#------------------------------------------------------------------------------

=head2 format_hex2

Returns the string representation of a byte in hexadecimal as $HH.

=cut

#------------------------------------------------------------------------------
sub format_hex2 { 
	sprintf("\$%02X", $_[0] & 0xFF) 
}
#------------------------------------------------------------------------------

=head2 format_hex4

Returns the string representation of a word in hexadecimal as $HHHH.

=cut

#------------------------------------------------------------------------------
sub format_hex4 { 
	sprintf("\$%04X", $_[0] & 0xFFFF) 
}
#------------------------------------------------------------------------------

=head2 format_bin8

Returns the string representation of a word in binary as %01010101.

=cut

#------------------------------------------------------------------------------
sub format_bin8 {
	my($val) = @_;

	my $sign = '';
	if ($val < 0) {
		$val = -$val;
		$sign = '-';
	}

	my $digits = '';
	while ($val != 0 || length($digits) < 8) {
		$digits = (($val & 1) ? '1' : '0') . $digits;
		$val >>= 1;
	}
	
	return $sign.'%'.$digits;
}
#------------------------------------------------------------------------------

=head2 format_dis

Returns the string representation of a signed byte in hexadecimal as +$HH, -$HH or
empty string for zero.

=cut

#------------------------------------------------------------------------------
sub format_dis {
	my($arg) = @_;
	$arg < 0 ? '-'.format_hex(-$arg) : 
	$arg > 0 ? '+'.format_hex( $arg) : 
	''; 
}
#------------------------------------------------------------------------------

=head2 format_str

Returns the string representation of an assembly string: double-quoted, all
double-quotes inside are escaped.

=cut

#------------------------------------------------------------------------------
sub format_str {
	my($str) = @_;
	$str =~ s/(["\\])/\\$1/g;
	return '"'.$str.'"';
}
#------------------------------------------------------------------------------

=head1 BUGS, FEEDBACK, AUTHORS, COPYRIGHT and LICENCE

See L<CPU::Z80::Disassembler|CPU::Z80::Disassembler>.

=cut

1;
