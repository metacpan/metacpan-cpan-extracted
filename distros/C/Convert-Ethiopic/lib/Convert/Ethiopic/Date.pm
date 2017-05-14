package Convert::Ethiopic::Date;


BEGIN
{
	use strict;
	use vars qw($VERSION $DEFAULTLANG);

	$VERSION = '0.11';

	require 5.000;

	require Convert::Ethiopic;
	require Convert::Ethiopic::Number;
	use Convert::Ethiopic::System;

	$DEFAULTLANG = $gez;
}


sub new
{
my $self = {};


	my $blessing = bless $self, shift;


	# $self->{LCInfo}   = $WITHUTF8;
	$self->{LCInfo}   = 0;
	$self->{langOut}  = $DEFAULTLANG;
	$self->{calsys} = "euro";

	if ( @_ && ( (ref($_[0]) eq "HASH") || ($#_ > 5) ) ) {
		my $args = ( ref($_[0]) eq "HASH" ) ? shift : { @_ };

		$self->{calsys} =
		( exists($args->{cal}) && $args->{cal} eq "ethio" ) 
		? "ethio"
		: "euro"
		;
		if ( exists($args->{date}) ) {
			if ( $args->{date} eq "today" ) {
				$self->today;
			}
			else {
				$self->{date}  = $args->{date};
				$self->{month} = $args->{month};
				$self->{year}  = $args->{year};
			}
		}
	}
	elsif ( $#_ ) {
		$self->{calsys} = ( $#_ == 3 ) ? shift : "euro";
		$self->{date}   = shift;
		$self->{month}  = shift;
		$self->{year}   = shift;
	}
	else {  
		#
		# one argument passed;
		#
		$_ = shift;
		$self->{calsys} = ( /^(\w+)$/ ) ? $_ : ( $_ == $eng ) ? "euro" : "ethio";
		$self->{langOut} = $_ unless ( $1 || /today/i );
		$self->today if ( /today/i || $_[0] =~ /today/i );
	}


	$blessing;

}


sub lang
{
my $self = shift;


	$self->{langOut} = $_[0] if ( @_ );

	$self->{langOut};

}


sub calsys
{
my $self = shift;


	$self->{calsys} = $_[0] if ( @_ );

	$self->{calsys};

}


sub toEthiopic
{
	my $r = Convert::Ethiopic::Date::_toEthiopic ( @_ );
	( wantarray ) ? ( $r->{date}, $r->{month}, $r->{year} ) : $r;
}


sub toGregorian
{
	my $r = Convert::Ethiopic::Date::_toGregorian ( @_ );
	( wantarray ) ? ( $r->{date}, $r->{month}, $r->{year} ) : $r;
}


sub convert
{
	my $r = Convert::Ethiopic::Date::_convert ( @_ );
	( wantarray ) ? ( $r->{date}, $r->{month}, $r->{year} ) : $r;
}


sub today
{
my $self = shift;

	my @TimeNow     = localtime;
	$self->{date}   = $TimeNow[3];
	$self->{month}  = $TimeNow[4] + 1;
	$self->{year}   = $TimeNow[5] + 1900;
	$self->{calsys} = "euro";

}


sub getDayOfWeek
{
	( $_[0]->{calsys} eq "euro" )
	? $_[0]->getEuroDayOfWeek
	: $_[0]->getEthiopicDayOfWeek
	;
}



sub getEuroDayOfWeek 
{
my $self = shift;

	my $f = ( $self->{calsys} eq "euro" ) ? $self->gregorianToFixed : $self->ethiopicToFixed ;

	( "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" )[ $f % 7 ];

}



sub getMonthName
{
	( $_[0]->{calsys} eq "euro" )
	? $_[0]->getEuroMonthName
	: $_[0]->getEthiopicMonthName
	;
}



sub getEuroMonthName
{
my $self = shift;

	my $month
	= ( $self->{calsys} eq "euro" ) 
	  ? $self->{month}
	  : $self->_toGregorian->{month}
	;

	( "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" )[ $month-1 ];

}



sub isEthiopianHoliday
{
my $self = shift;

	( $self->{calsys} eq "ethio" ) 
	? $self->_isEthiopianHoliday
	: $self->_toEthiopic->_isEthiopianHoliday
	;
}



sub getEthiopicYearName
{
my $self = shift;

	( $self->{calsys} eq "ethio" ) 
	? $self->_getEthiopicYearName
	: $self->_toEthiopic->_getEthiopicYearName
	;
}



sub getEthiopicMonthName
{
my $self = shift;

	( $self->{calsys} eq "ethio" ) 
	? $self->_getEthiopicMonthName
	: $self->_toEthiopic->_getEthiopicMonthName
	;
}



sub getEthiopicDayOfWeek
{
my $self = shift;

	( $self->{calsys} eq "ethio" ) 
	? $self->_getEthiopicDayOfWeek
	: $self->_toEthiopic->_getEthiopicDayOfWeek
	;
}



sub getEthiopicDayName
{
my $self = shift;

	( $self->{calsys} eq "ethio" ) 
	? $self->_getEthiopicDayName
	: $self->_toEthiopic->_getEthiopicDayName
	;
}


sub getFormattedDate
{
my $self = shift;
my $formattted;




	if ( $self->{calsys} eq "euro" ) {
		my ( $day, $month ) = ( $self->getEuroDayOfWeek, $self->getEuroMonthName );
		$formatted = "$day, $month $self->{date}, $self->{year}";
	}
	else {
		my ( $day, $month, $year ) = $self->getDayMonthYearDayName;
		$formatted  = "$day�� $month $self->{date}";

		$formatted .= ( $self->{langOut} == $tir )
		            ? "መዓልቲ"
			    : "ቀን",
			    ;

		$formatted .= $year;

		$formatted .= ( $self->{year} > 0 )
		            ?  "ዓ/ም"
			    :  "ዓ/አ"
			    ;
	}

	$formatted;

}



sub getDayMonthYearDayName
{
my $self = shift;

	my $n = new Convert::Ethiopic::Number ( $self->{year} );
	my @result = 
	(
		$self->getEthiopicDayOfWeek,
		$self->getEthiopicMonthName,
		$n->convert,
		$self->getEthiopicDayName,
	);

	( wantarray ) ? @result : \@result;
}
#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

Ethiopic::Time - conversions of calendar systems to/from Ethiopic and Gregorian.

=head1 SYNOPSIS

  use LiveGeez::Request;
  require Convert::Ethiopic::Time;
  my $r = LiveGeez::Request->new;

	ReadParse ( \%input );
	$r->ParseInput ( \%input );

	my $t = Convert::Ethiopic::Time->new ( $r );

	$t->GregorianToEthiopic;

	print "$t->{euDay}/$t->{euMonth}/$t->{euYear} = ";
	print "$t->{etDay}/$t->{etMonth}/$t->{etYear}\n" 

=head1 DESCRIPTION

Ethiopic::Time and Ethiopic::Cstocs are designed as interfaces to the methods in the
Ethiopic:: module and is oriented as services for the LiveGeez:: module.  In this
version Ethiopic::Time expects to receive an object with hash elements using
the keys:

=over 4

=item 'calIn'

which can be "euro or "ethio".

=item  'date'

a comma separated list as "day,month,year".

=item 'LCInfo'

locale settings I<see the LibEth man pages>.

=back

These keys are set when using a LiveGeez::Request object as shown in the example.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

perl(1).  LiveGeez(3), L<http://libeth.netpedia.net|http://libeth.netpedia.net>

=cut
