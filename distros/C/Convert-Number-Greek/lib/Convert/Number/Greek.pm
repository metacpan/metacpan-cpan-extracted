package Convert::Number::Greek;

require 5.008;
use strict;   # :-(
use warnings; # :-(
use POSIX 'floor';
use utf8;
require Exporter;


=head1 NAME

Convert::Number::Greek - Convert between Arabic and Greek numerals

=cut


use vars qw[
	@ISA
	@EXPORT_OK
	$VERSION
	@greek_digits
	@greek_digits_uc
];

$VERSION   = '0.02';
@ISA       = 'Exporter';
@EXPORT_OK = qw'num2greek greek2num';


=head1 VERSION

Version 0.02

=head1 SYNOPSIS

  use Convert::Number::Greek qw'num2greek greek2num';
  
  $greek_number = num2greek 1996;
  # $greek_number now contains
  # "\x{375}\x{3b1}\x{3e1}\x{3df}\x{3db}\x{374}"

  $number = greek2num "\x{3b5}\x{3c3}\x{3c4}\x{3b6}'";
  # $number now contains 567
  
=head1 DESCRIPTION

This module provides subroutines for converting between Arabic and
Greek numbers.


=head1 FUNCTIONS

=over 4

=item num2greek ( NUMBER, { OPTIONS } )

num2greek converts an Arabic numeral to a Greek numeral in the form of
a Unicode string the syntax is as follows:

NUMBER is the number to convert. It should be a string of digits,
nothing more (see L<BUGS>, below). OPTIONS (optional) is a reference
to a hash of boolean options. The options available are as follows:
   
 Option Name    Default Value   Description
 upper          0               Use uppercase Greek letters
 uc             0                "      "       "      "
 stigma         1               Use the stigma for 6 as opposed to
                                sigma followed by tau
 arch_koppa     0               Use the archaic koppa instead of
                                the modern one
 numbersign     1               Append a Greek number sign (U+0374)
                                to the resulting string
	 
When you specify options, C<undef> is treated as false, so
   
    num2greek $some_number, { uc => 1, stigma }

actually means

    num2greek $some_number, { uc => 1, stigma => 0 }

=cut
   


@greek_digits = (
	['', qw[α β γ δ ε ϛ ζ η θ]],
	['', qw[ι κ λ μ ν ξ ο π ϟ]],
	['', qw[ρ σ τ υ φ χ ψ ω ϡ]],
);
@greek_digits_uc = (
	['', qw[Α Β Γ Δ Ε Ϛ Ζ Η Θ]],
	['', qw[Ι Κ Λ Μ Ν Ξ Ο Π Ϟ]],
	['', qw[Ρ Σ Τ Υ Φ Χ Ψ Ω Ϡ]],
);

sub num2greek ($;$) {
	my ($n, $options) = @_;
	my $ret;

	$options ||= {};

	my @digits = $$options{uc} || $$options{upper} ? @greek_digits_uc : @greek_digits;
	
	exists $$options{stigma} and !$$options{stigma} and
		local $digits[0][6] = $digits[0][6] eq 'ϛ' ? 'στ' : 'ΣΤ';
	$$options{arch_koppa} and
		local $digits[1][9] = $digits[1][9] eq 'ϟ' ? 'ϙ' : 'Ϙ';
	
	for my $place ( reverse 0 .. length($n) - 1 ) {
		my $digit = substr $n, length($n) - $place - 1, 1;
		
		$ret .= '͵' x floor($place / 3) . # thousands indicator
			$digits[$place % 3][$digit];
			
	}
	$ret .= 'ʹ' unless exists $$options{numbersign} and !$$options{numbersign};
	$ret;
}

=item greek2num ( STRING )

=for comment
later it will be  =item greek2num ( STRING, { OPTIONS } )

The C<greek2num> function parses a Greek numbers and returns the
Arabic equivalent.

STRING is a string consisting of a Greek number. Anything following
the number will be ignored, but will raise a warning if
S<C<use warnings 'numeric'>> is on (unless it's just whitespace).

Currently no options are available.

=for comment OPTIONS is a
reference to a hash of booleans. The only option available at present
is C<strict>, which requires the digits to be in standard
order; id est, most significant digits first.

=cut

our %greek_digit_2_num = qw(
	α	1
	β	2
	γ	3
	δ	4
	ε	5
	ϛ	6
	ζ	7
	η	8
	θ	9
	ι	10
	κ	20
	λ	30
	μ	40
	ν	50
	ξ	60
	ο	70
	π	80
	ϟ	90
	ρ	100
	σ	200
	τ	300
	υ	400
	φ	500
	χ	600
	ψ	700
	ω	800
	ϡ	900
	Α	1
	Β	2
	Γ	3
	Δ	4
	Ε	5
	Ϛ	6
	Ζ	7
	Η	8
	Θ	9
	Ι	10
	Κ	20
	Λ	30
	Μ	40
	Ν	50
	Ξ	60
	Ο	70
	Π	80
	Ϟ	90
	Ρ	100
	Σ	200
	Τ	300
	Υ	400
	Φ	500
	Χ	600
	Ψ	700
	Ω	800
	Ϡ	900
	ϙ	90
	Ϙ	90
	ᾳ	1000
	ῃ	8000
	ῳ	800000
	ᾼ	1000
	ῌ	8000
	ῼ	800000
);

sub greek2num ($;$) {
	my($n,$ret,$thousands,$digit) = $_[0];

	$n =~ s/^\s+//;

	while (length $n) {
		$thousands = $n =~ s/^([͵,]+)// && length $1;
		if($n =~ s/^στ//i) {
			$digit = 6;
		}
		elsif(exists $greek_digit_2_num{substr $n,0,1}) {
			$digit = $greek_digit_2_num{substr $n,0,1,''};
		}
		else {
			$n =~ s/^['’ʹ´΄]?\s*//; # straight quote, smart
			length $n or last;      # quote,  number  sign,
			warnings::warnif(       # oxia, tonos
			    numeric =>
			    qq/Argument "$_[0]" isn't numeric in greek2num/
			);
			last;
		}
		$ret += $digit * 1000**$thousands;
	}
	$ret;
}

=back

=head1 EXPORTS

None by default, but you get C<num2greek> and C<greek2num> if you ask
for them (politely).

=head1 DIAGNOSTICS

The greek2num function will trigger a "non-numeric" warning if you
S<C<use warnings 'numeric'>>. 

=head1 COMPATIBILITY

This module requires perl 5.8.0 or later, though the earliest version
I have tested it with is 5.8.1.

=head1 BUGS

The C<num2greek> function does not yet have any error-checking
mechanism in place. The input should be a string of Arabic digits, or
at least a value that stringifies to such. Using an argument that does
not fit this description may produce nonsensical results.

=head1 AUTHOR

Father Chrysostomos <sprout @cpan.org>

=cut




