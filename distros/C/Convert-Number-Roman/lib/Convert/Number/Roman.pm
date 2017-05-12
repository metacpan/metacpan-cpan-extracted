package Convert::Number::Roman;

use utf8;  # can't find a way to conditionally load this with
           # the scope applying throughout

BEGIN
{
	use strict;
	use vars qw($VERSION %RomanDigits);

	$VERSION = '0.01';

	require 5.000;

	%RomanDigits =(
		Ⅰ	=> 1,
		Ⅱ	=> 2,
		Ⅲ	=> 3,
		Ⅳ	=> 4,
		Ⅴ	=> 5,
		Ⅵ	=> 6,
		Ⅶ	=> 7,
		Ⅷ	=> 8,
		Ⅸ	=> 9,
		Ⅹ	=> 10,
		Ⅺ	=> 11,
		Ⅻ	=> 12,
		Ⅼ	=> 50,
		Ⅽ	=> 100,
		Ⅾ	=> 500,
		Ⅿ	=> 1000,
		ↁ	=> 5000,
		ↂ	=> 10000
	);
}


sub _setArgs
{
my ($self, $number, $style) = @_;

	if ( $#_ > 2 ) {
		warn (  "too many arguments." );
		return;
	}
	if ( $number =~ /lower|upper/ ) {
		$style  = $number;
		$number = undef;
	}
	if ( $number ) {
		unless ( $number =~ /^\d+$/ || $number =~ /^[̄̿Ⅰ-ↂ]+$/ ) {
			warn (  "'$number' is not a number." );
			return;
		}
		else {
			$self->{number} = $number;
		}
	}
	if ( $style ) {
		if ( $style =~ /lower|upper/i ) {
			$self->{style} = lc($style);
		}
		else {
			warn (  "'$style' is not a supported style, using 'upper'." );
		}
	}
	


1;
}


sub new
{
my $class = shift;
my $self  = {};


	my $blessing = bless ( $self, $class );

	$self->{number} = undef;
	$self->{style}  = "upper";

	$self->_setArgs ( @_ ) || return if ( @_ );

	$blessing;
}


sub _fromRoman
{

	$_ = $_[0]->{number};
	#
	# convert to uppercase roman:
	#
	tr/ⅰ-ⅿ/Ⅰ-Ⅿ/;  # get on up!
	#
	# just return if its a single char:
	#
	return ( $RomanDigits{$_} ) if ( length($_) == 1);
	#
	# make into math:
	#
	s/̿/̄̄/og;
	while ( /[Ⅰ-ↂ](̄+)/ ) {
		my $power = $1;
		my $group;
		s/([Ⅰ-ↂ])$power/$group .= $1; "$1$power";/eg;
		s/([Ⅰ-ↂ]$power)+/($group)*($power)/;
	}
	s/̄/*1000/og;
	s/Ⅿↂ/+9000/og;
	s/Ⅿↁ/+4000/og;
	s/ⅭⅯ/+900/og;
	s/ⅭⅮ/+400/og;
	s/ⅩⅭ/+90/og;
	s/ⅩⅬ/+40/og;
	s/([ↁⅮⅬ])/+$RomanDigits{$1}/og;
	s/([ↂⅯⅭⅩ])/+$RomanDigits{$1}/og;
	s/([Ⅰ-Ⅻ])/+$RomanDigits{$1}/og;
	s/\([+*]/(/g;
	s/\)\(/\)+\(/g;
	s/\(([\d+]+)\)/eval"$1"/eg;
	s/^\+//;
	#
	# evaluate the expression:
	#
	eval "$_";
}


sub _toRoman
{
my ($self, $number) = @_;
$number = $self->{number} unless ( defined($number) );

	$number =~ s/^0+//;  # strip leading zeros

	my $roman;
if ( $number >= 40000 ) {
	my $lines;
	while ( $number ) {
		$number =~ s/(\d{1,3})$//; 
		my $group = $1;
		if ( $group != /^0+$/ ) {
			if ( $lines ) {
				my $rGroup = $self->_toRoman ( $group );
				$rGroup =~ s/(.)/$1$lines/g;
				$roman = ( $roman ) ? "$rGroup$roman" : $rGroup;
			}
			else {
				# first cycle
				$roman = $self->_toRoman ( $group );

			}
		}
		$lines .= "̄";
	}

	$roman =~ s/̄̄/̿/g;

} else {
	while ( $number ) {
		if ( $number >= 10000 ) {
			$roman .= "ↂ";
			$number -= 10000;
		}
		elsif ( $number >= 9000 ) {
			$roman .= "Ⅿↂ";
			$number -= 9000;
		}
		elsif ( $number >= 5000 ) {
			$roman .= "ↁ";
			$number -= 5000;
		}
		elsif ( $number >= 4000 ) {
			$roman .= "Ⅿↁ";
			$number -= 4000;
		}
		elsif ( $number >= 1000 ) {
		 	$roman .= "Ⅿ";
		 	$number -= 1000;
		}
		elsif ( $number >= 900 ) {
			$roman .= "ⅭⅯ";
			$number -= 900;
		}
		elsif ( $number >= 500 ) {
			$roman .= "Ⅾ";
			$number -= 500;
		}
		elsif ( $number >= 400 ) {
			$roman .= "ⅭⅮ";
			$number -= 400;
		}
		elsif ( $number >= 100 ) {
			$roman .= "Ⅽ";
			$number -= 100;
		}
		elsif ( $number >= 90 ) {
			$roman .= "ⅩⅭ";
			$number -= 90;
		}
		elsif ( $number >= 50 ) {
			$roman .= "Ⅼ";
			$number -= 50;
		}
		elsif ( $number >= 40 ) {
			$roman .= "ⅩⅬ";
			$number -= 40;
		}
		elsif ( $number > 12 ) {
			$roman .= "Ⅹ";
			$number -= 10;
		}
		elsif ( $number >= 10 ) {
			$number -= 10;
			$number =~ tr/0-2/Ⅹ-Ⅻ/;
			$roman .= $number;
			$number = 0;
		}
		else {
			$number =~ tr/1-9/Ⅰ-Ⅸ/;
			$roman .= $number;
			$number = 0;
		}
	}
}

	$roman;
}


sub upperRoman
{
my ( $self, $roman ) = @_;

	$roman =~ tr/ⅰ-ⅿ/Ⅰ-Ⅿ/;
	$roman;
}


sub lowerRoman
{
my ( $self, $roman ) = @_;

	$roman =~ tr/Ⅰ-Ⅿ/ⅰ-ⅿ/;
	$roman;
}


sub convert
{
my $self = shift;

	#
	# reset string if we've been passed one:
	#
	$self->_setArgs ( @_ ) if ( @_ );

	my $roman
	= ( $self->number =~ /^[0-9]+$/ )
	  ? $self->_toRoman
	  : $self->_fromRoman
	;

	( $self->{style} eq "upper" )
	  ? $roman
	  : $self->lowerRoman ( $roman )
	;
}


sub number
{
my $self = shift;

	$self->_setArgs ( @_ ) || return
		if ( @_ );

	$self->{number};
}


sub style
{
my $self = shift;

	$self->_setArgs ( @_ ) || return
		if ( @_ );

	$self->{style};
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

Convert::Number::Roman - Convert Between Western and Roman Numeral Systems

=head1 SYNOPSIS

 #
 #  instantiate with a Western or Roman number (in UTF-8)
 #
 my $n = new Convert::Number::Roman( 4294967296 );
 my $romanNumber = $n->convert;

 $n->number ( 54321 );    # reset number handle
 print $n->convert, "\n";
 print $n->convert ( "lower" ), "\n";  # convert in lowercase numerals

 print "2003 => ", $n->convert ( 2003 ), "\n";  # convert new number


=head1 DESCRIPTION

Implementation of the Roman numeral conversion algorithm proposed for
the CSS3-List module specification.  Use to convert between Western and
Roman numeral systems under Unicode.

=over 4

=item See: L<http://www.w3.org/TR/css3-lists/>

=back

Roman numerals have both uppercase and lowercase styles.  The default
style used is the uppercase.  The default style can be set at instantiation
time as per:

 my $n = new Convert::Number::Roman( "lower" );

or

 my $n = new Convert::Number::Roman( 4294967296, "lower" );

The default style may also be set during conversion as per:


 $n->convert( "lower" );

or

 $n->convert( 4294967296, "lower" );

The C<style> method is also available to set or query the default style:


 my $style = $n->style;  # query style

 $n->style( "upper" );   # reset style


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

=head1 SEE ALSO

L<Math::Roman>    L<Text::Roman>    L<Roman>

L<Convert::Number::Coptic>    L<Convert::Number::Ethiopic>    L<Convert::Number::Digits>


Included with this package:

  examples/numbers.pl   examples/roman.pl

=cut
