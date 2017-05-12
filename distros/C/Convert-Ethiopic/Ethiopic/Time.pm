package Convert::Ethiopic::Time;

$VERSION = '0.10';

require 5.000;

use Convert::Ethiopic;
use Convert::Ethiopic::Cstocs;

($unicode, $utf8) = ( $Convert::Ethiopic::System::unicode,  $Convert::Ethiopic::System::utf8 );


sub new
{
my $class   = shift;
my $request = shift;
my $self    = {};


	if ( $request->{calIn} eq "euro" ) {
	    if ( $request->{euDay} ) {
			( $self->{euDay}, $self->{euMonth}, $self->{euYear} ) =
			( $request->{euDay}, $request->{euMonth}, $request->{euYear} )
	    } else {
			( $self->{euDay}, $self->{euMonth}, $self->{euYear} ) = split ( /,/, $request->{date} );
		}
	}
	else {
	    if ( $request->{etDay} ) {
			( $self->{etDay}, $self->{etMonth}, $self->{etYear} ) =
			( $request->{etDay}, $request->{etMonth}, $request->{etYear} )
	    } else {
			( $self->{etDay}, $self->{etMonth}, $self->{etYear} ) = split ( /,/, $request->{date} );
		}
	}

	$self->{request} = $request;

	bless $self, $class;

}


sub GregorianToEthiopic
{
my $self = shift;


	return ( 0 )
		if ( isBogusGregorianDate ( $self->{euDay}, $self->{euMonth}, $self->{euYear} ) );


	#
	#  We need these temporary holders since the arguements to
	#  EthiopicToGregorian get over written.
	#
	local ($xDay, $xMonth, $xYear) = ($self->{euDay}, $self->{euMonth}, $self->{euYear});

	GregorianToEthiopic ( $xDay, $xMonth, $xYear );

	( $self->{etDay}, $self->{etMonth}, $self->{etYear} ) = ( $xDay, $xMonth, $xYear );

	return ( $self->{etDay}, $self->{etMonth}, $self->{etYear} );

}


sub EthiopicToGregorian
{
my $self = shift;


	return ( 0 )
		if ( isBogusEthiopicDate ( $self->{etDay}, $self->{etMonth}, $self->{etYear} ) );


	#
	#  We need these temporary holders since the arguements to
	#  EthiopicToGregorian get over written.
	#
	local ($xDay, $xMonth, $xYear) = ($self->{etDay}, $self->{etMonth}, $self->{etYear});

	EthiopicToGregorian ( $xDay, $xMonth, $xYear );

	( $self->{euDay}, $self->{euMonth}, $self->{euYear} ) = ( $xDay, $xMonth, $xYear );

	return ( $self->{euDay}, $self->{euMonth}, $self->{euYear} );

}


sub isEthiopianHoliday 
{
my $self = shift;


	return ( isEthiopianHoliday ( $self->{etDay}, $self->{etMonth}, $self->{etYear}, $self->{request}->{sysOut}->{LCInfo} ) );

}


sub getEuroDayOfWeek 
{
my $self = shift;


	$self->EthiopicToGregorian if !( $self->{euDay} || $self->{euMonth} || $self->{euYear} );

	return ( ( "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" )[ GregorianToFixed ( $self->{euDay}, $self->{euMonth}, $self->{euYear} ) % 7 ] );

}


sub getEuroMonth
{
my $self = shift;


	$self->EthiopicToGregorian if !( $self->{euMonth} );

	return ( ( "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" )[ $self->{euMonth}-1 ] );

}


sub getEthioMonth
{
my $self = shift;


	$self->GregorianToEthiopic if !( $self->{etDay} || $self->{etMonth} || $self->{etYear} );


	return ( getEthiopicMonth ( $self->{etMonth}, $self->{request}->{langNum}, $self->{request}->{sysOut}->{LCInfo} ) );

}


sub getDayMonthYearDayName
{
my $self = shift;


	$self->GregorianToEthiopic if !( $self->{etDay} || $self->{etMonth} || $self->{etYear} );

	my $tempSysOutNum  = $self->{request}->{sysOut}->{sysNum};
	my $tempxferOutNum = $self->{request}->{sysOut}->{xferNum};
	$self->{request}->{number} = $self->{etYear};

	$self->{request}->{sysOut}->{sysNum}  = $unicode;
	$self->{request}->{sysOut}->{xferNum} = $utf8;

	my $Y = EthiopicNumber ( $self->{request} );

	$self->{request}->{sysOut}->{sysNum}  = $tempSysOutNum;
	$self->{request}->{sysOut}->{xferNum} = $tempxferOutNum;

	return (
		getEthiopicDayOfWeek ( $self->{etDay}, $self->{etMonth}, $self->{etYear}, $self->{request}->{langNum}, $self->{request}->{sysOut}->{LCInfo} ),
		getEthiopicMonth ( $self->{etMonth}, $self->{request}->{langNum}, $self->{request}->{sysOut}->{LCInfo} ),
	    $Y,
		getEthiopicDayName ( $self->{etDay}-1, $self->{etMonth}, $self->{request}->{sysOut}->{LCInfo} )
	);

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
