package Convert::Number::Coptic;

use utf8;  # can't find a way to conditionally load this with
           # the scope applying throughout

BEGIN
{
	use strict;
	use warnings;
	use vars qw($VERSION @CNumbers %CNumbers);

	$VERSION = "0.14";

	require 5.000;

	@CNumbers =(
		["α", "β", "γ", "δ", "ε", "ϛ", "ζ", "η", "θ"],
		["ι", "κ", "λ", "μ", "ν", "ξ", "ο", "π", "ϥ"],
		["ρ", "ϲ", "τ", "υ", "φ", "χ", "ψ", "ω", "ϣ"]
	);
	%CNumbers =(
		'α'	=> 1,
		'β'	=> 2,
		'γ'	=> 3,
		'δ'	=> 4,
		'ε'	=> 5,
		'ϛ'	=> 6,
		'ζ'	=> 7,
		'η'	=> 8,
		'θ'	=> 9,
		'ι'	=> 10,
		'κ'	=> 20,
		'λ'	=> 30,
		'μ'	=> 40,
		'ν'	=> 50,
		'ξ'	=> 60,
		'ο'	=> 70,
		'π'	=> 80,
		'ϥ'	=> 90,
		'ρ'	=> 100,
		'ϲ'	=> 200,
		'τ'	=> 300,
		'υ'	=> 400,
		'φ'	=> 500,
		'χ'	=> 600,
		'ψ'	=> 700,
		'ω'	=> 800,
		'ϣ'	=> 900
	);

}


sub _setArgs
{
my $self = shift;

	if ( $#_ ) {
		warn (  "too many arguments." );
		return;
	}
	my $number = shift;
	unless ( ($number =~ /^\d+$/) || ($number =~ /([α-ρς-ωϛϲ])/) ) {
		warn (  "$number is not a number." );
		return;
	}

	$self->{number} = $number;

1;
}


sub new
{
my $class = shift;
my $self  = {};

	my $blessing = bless ( $self, $class );

	$self->{number} = undef;

	$self->_setArgs ( @_ ) || return if ( @_ );

	$blessing;
}


sub _fromCoptic
{
	$_ = $_[0]->{number};
	s/̄//og;
	s/̱/000/og;
	s/͇/000000/og;
	s/([α-ρς-ωϛϲ])/$CNumbers{$1}/og;

	my $out = 0;
	s/(\d0+)/$out += $1/oge;
	s/(\d)$/$out += $1/oe;

	$out;
}


sub toCoptic
{
my $number = $_[0]->{number};

	my $n = length ( $number ) - 1;

	# map and return a single digit number
	# don't waste time with the loop:
	return ( "$CNumbers[0][$number-1]̄" ) unless ( $n );


	my @aNumberString = split ( //, $number );
	my $cNumberString = "";


	#
	#  read number from most to least significant digits:
	#
	for ( my $place = $n; $place >= 0; $place-- ) {

		my $pos    = $place % 3;
		my $cycles = int $place / 3;

		my $aNum       = $aNumberString[$n-$place];
		next unless ( $aNum );
		$cNumberString .= $CNumbers[$pos][$aNum-1];

		if ( $cycles ) {
			#
			#  add an even number of = symbols
			#
			for ( my $i = 0; $i<(int $cycles/2); $i++ ) {
				$cNumberString .= "͇";
			}
			$cNumberString .= "̱"  if ( $cycles % 2 );  # if odd
		}
		else {
			$cNumberString .= "̄";
		}

	}

	$cNumberString;
}


sub convert
{
my $self = shift;

	#
	# reset string if we've been passed one:
	#
	$self->number ( @_ ) if ( @_ );

	( $self->number =~ /^[0-9]+$/ )
	  ? $self->toCoptic
	  : $self->_fromCoptic
	;
}


sub number
{
my $self = shift;

	$self->_setArgs ( @_ ) || return
		if ( @_ );

	$self->{number};
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

Convert::Number::Coptic - Convert Between Western and Coptic Numeral Systems

=head1 SYNOPSIS

 #
 #  instantiate with a Western or Coptic number (in UTF-8)
 #
 my $n = new Convert::Number::Coptic ( 12345 );
 my $copNumber = $n->convert;

 $n->number ( 54321 );    # reset number handle
 print $n->convert, "\n";

 print "2002 => ", $n->convert ( 2002 ), "\n";  # convert new number


=head1 DESCRIPTION

Use to convert between Western and Coptic numeral systems.

=head2 Assumptions and Limitations

Coptic numerals can be formatted in two ways.  The standard convention
is to use only underlines from 10^3 and onward.  A lesser used convention
accumulates only overlines.  This package uses the standard convention.

Unicode does not define which diacritical symbols should be used for
composing Coptic numerals.  The solution here is to use U+0304 for single
overline, U+0331 for single underline and U+0347 for double underline.

Since Unicode lacks diacritical symbols to build up numbers indefinitely
(can't blame Unicode here) a complication arises for numbers of 1 billion
or larger.  Since there is no triple or quadruple, etc, underline non-spacing
diacritical marks, this package simply appends extra diacritical symbols.
For example:

  10^5 => (U+03C1)(U+0331)
  10^6 => (U+03B1)(U+0347)
  10^7 => (U+03B9)(U+0347)
  10^8 => (U+03C1)(U+0347)
  10^9 => (U+03B1)(U+0347)(U+0331)
  10^10 => (U+03B9)(U+0347)(U+0331)
  10^11 => (U+03C1)(U+0347)(U+0331)
  10^12 => (U+03B1)(U+0347)(U+0347)
    :   :      :       :       :

The shared Greek-Coptic range of Unicode is used by this package.  This
will be update when Unicode is revised to better support Coptic.

=over 4

=item See: L<http://www.ethiopic.org/Numerals/>

=back

=head1 REQUIRES

The package is known to work on Perl 5.6.1 and 5.8.0 but has not been tested on
other versions of Perl by the author. 

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2025, Daniel Yacob C<< <dyacob@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

L<Convert::Number::Ethiopic>    L<Convert::Digits>

Included with this package:

  examples/numbers.pl

=cut
