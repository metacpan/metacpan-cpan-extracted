package Convert::Number::Ethiopic;

use utf8;  # can't find a way to conditionally load this with
           # the scope applying throughout

BEGIN
{
	use strict;
	use vars qw($VERSION @ENumbers %ENumbers);

	$VERSION = "0.16";

	require 5.000;

	@ENumbers =(
		"፩", "፪", "፫", "፬", "፭", "፮", "፯", "፰", "፱",
		"፲", "፳", "፴", "፵", "፶", "፷", "፸", "፹", "፺",
		"፻", "፼"
	);
	%ENumbers =(
		'፩'	=> 1,
		'፪'	=> 2,
		'፫'	=> 3,
		'፬'	=> 4,
		'፭'	=> 5,
		'፮'	=> 6,
		'፯'	=> 7,
		'፰'	=> 8,
		'፱'	=> 9,
		'፲'	=> 10,
		'፳'	=> 20,
		'፴'	=> 30,
		'፵'	=> 40,
		'፶'	=> 50,
		'፷'	=> 60,
		'፸'	=> 70,
		'፹'	=> 80,
		'፺'	=> 90,
		'፻'	=> 100,
		'፼'	=> 10000
	);

}


sub _setArgs
{
my ($self, $number) = @_;

	if ( $#_ > 1 ) {
		warn (  "too many arguments." );
		return;
	}
	unless ( $number =~ /^\d+$/ || $number =~ /^[፩-፼]+$/ ) {
		warn (  "'$number' is not a number." );
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


sub _fromEthiopic
{

	#
	# just return if its a single char
	#
	return ( $ENumbers{$_[0]->{number}} ) if ( length($_[0]->{number}) == 1);


	$_ = $_[0]->{number};

	#
	#  tack on a ፩ to avoid special condition check
	#
	s/^([፻፼])/፩$1/o;
	s/፼፻/፼፩፻/og;

	# what we do now is pad 0s around ፻ and ፼, these regexi try to kill
	# two birds with one stone but could be split and simplified

	#
	# pad 0 around ones and tens
	#
	s/([፻፼])([፩-፱])/$1."0$2"/oge;    # add 0 if tens place empty
	s/([፲-፺])([^፩-፱])/$1."0$2"/oge;  # add 0 if ones place empty
	s/([፲-፺])\b/$1."0"/oe;           # repeat at end of string


	# pad 0s for meto
	#
	#  s/(፻)$/$1."00"/e;  # this is stupid but tricks perl 5.6 into working
	s/፻\b/፻00/o;

	# pad 0s for ilf
	#
	s/፼\b/፼0000/o;
	s/፼፼/፼0000፼/og;  # since /g doesn't work the first time..
	s/፼፼/፼0000፼/og;  # ...we do it again!
	s/፻፼/፼00፼/og;
	s/፼0([፩-፱])፼/፼000$1፼/og;
	s/፼0([፩-፱])\b/፼000$1/o;          # repeat at end of string
	s/፼([፲-፺]0)፼/፼00$1፼/og;
	s/፼([፲-፺]0)\b/፼00$1/o;           # repeat at end of string
	s/፼([፩-፺]{2})፼/፼00$1፼/og;
	s/፼([፩-፺]{2})\b/፼00$1/o;         # repeat at end of string

	s/[፻፼]//og;

	# fold tens:
	#
	tr/፲-፺/፩-፱/;

	# translit digits:
	#
	tr/፩-፱/1-9/;

	int $_;
}


sub _toEthiopic
{
my $number = $_[0]->{number};

	my $n = length ( $number ) - 1;

	# map and return a single digit number
	# don't waste time with the loop:
	return ( $ENumbers[$number-1] ) unless ( $n );


	unless ( $n % 2 ) {
		#
		#  Add dummy leading 0 to precondition the number for
		#  the algorithm and reduce one logic test within the
		#  for loop
		#
		$number = "0$number";
		$n++;
	}

	my @aNumberString = split ( //, $number );
	my $eNumberString = "";


	#
	#  read number from most to least significant digits:
	#
	for ( my $place = $n; $place >= 0; $place-- ) {
		#
		#  initialize values to emptiness:
		#
		my ($aTen, $aOne) = ( 0, 0);  #    ascii ten's and one's place
		my ($eTen, $eOne) = ('','');  # ethiopic ten's and one's place


		#
		#  populate our tens and ones places from the number string:
		#
		$aTen = $aNumberString[$n-$place]; $place--;
		$aOne = $aNumberString[$n-$place];
		$eTen = $ENumbers[$aTen-1+9]       if ( $aTen );
		$eOne = $ENumbers[$aOne-1]         if ( $aOne );


		#
		#  pos tracks our 'pos'ition in a sequence of 4 digits
		#  to help determine what separator we need between
		#  a grouping of tens and ones.
		#
		my $pos = int ( $place % 4 ) / 2;  # make even/odd 


		#
		#  find a separator, if any, to follow ethiopic ten and one:
		#
		my $sep
		= ( $place )
		  ? ( $pos ) # odd
		    ? ( ($eTen ne '') || ($eOne ne '') )
		      ? '፻'
		      : ''
		    : '፼'
		  : ''
		;


		#
		#  if $eOne is an Ethiopic '፩' we want to clear it under
		#  under special conditions.  These ellision rules could be
		#  combined into a single big test but gets harder to read
		#  and manage:
		#
		# if ( ( $eOne eq '፩' ) && ( $eTen eq '' ) && ( $n > 1 ) ) {
		if ( ( $eOne eq '፩' ) && ( $eTen eq '' ) ) {
			if ( $sep eq '፻' ) {
				#
				#  A superflous implied ፩ before ፻
				#
				$eOne = '';
			}
			elsif ( ($place+1) == $n ) {   # recover from initial $place--
				#
				#  ፩ is the leading digit.
				#
				$eOne = '';
			}
		}


		#
		#  put it all together and append to our output number:
		#
		$eNumberString .= "$eTen$eOne$sep";	
	}

	$eNumberString;
}


sub convert
{
my $self = shift;


	#
	# reset string if we've been passed one:
	#
	$self->number ( @_ ) if ( @_ );

	( $self->number =~ /^[0-9]+$/ )
	  ? $self->_toEthiopic
	  : $self->_fromEthiopic
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

Convert::Number::Ethiopic - Convert Between Western and Ethiopic Numeral Systems

=head1 SYNOPSIS

 #
 #  instantiate with a Western or Ethiopic number (in UTF-8)
 #
 my $n = new Convert::Number::Ethiopic( 12345 );
 my $etNumber = $n->convert;

 $n->number ( 54321 );    # reset number handle
 print $n->convert, "\n";

 print "2002 => ", $n->convert ( 2002 ), "\n";  # convert new number


=head1 DESCRIPTION

Implementation of the Ilf-Radix numeral conversion algorithm entirely
in Perl.  Use to convert between Western and Ethiopic numeral systems.

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

=head1 SEE ALSO

L<Convert::Number::Coptic>    L<Convert::Digits>

Included with this package:

  examples/numbers.pl

=cut
