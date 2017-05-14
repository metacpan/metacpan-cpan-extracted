package Convert::Ethiopic::File;


BEGIN
{
	use strict;
	use vars qw($VERSION);

	$VERSION = '0.10';

	require 5.000;

	use Convert::Ethiopic;
	require Convert::Ethiopic::System;
}


sub _setArgs
{
my $self = shift;

	#  possible args are ( num, sysOut )
	#                    ( num )
	#                    ( sysOut )

	if ( $#_ > 3 ) {
	 	warn (  "to many arguments" );
	 	return;
	}

	foreach ( @_ ) {
		my $ref = ref ( $_ );
	 	if ( $ref && ( $ref =~ /::/ ) ) {
	 		if ( $_->isa ( "Convert::Ethiopic::System" ) ) {
	 			if ( $self->{sysIn} ) {
	 				$self->{sysOut} = $_;
	 			}
	 			else {
	 				$self->{sysIn}  = $_;
	 			}
	 		}
	 	}
	 	elsif ( $ref eq "GLOB" ) {
	 		if ( $self->{fileIn} ) {
	 			$self->{fileOut} = $_;
	 		}
	 		else {
	 			$self->{fileIn}  = $_;
	 		}
	 	}
	}
1;
}



sub new
{
my $class = shift;
my $self  = {};


	my $blessing = bless $self, $class;

	$self->{sysIn} = $self->{sysOut} = $self->{fileIn} = $self->{fileOut} = undef;

	$self->_setArgs ( @_ ) || return if ( @_ );

	$blessing;
}



sub convert
{
my $self = shift;


	#
	# set defaults if unset:
	#
	$self->{sysIn} = new Convert::Ethiopic::System ( "sera" )
		unless ( $self->{sysIn} );

	$self->{sysOut} = new Convert::Ethiopic::System ( "UTF8" )
		unless ( $self->{sysOut} );

	#
	# reset string if we've been passed one:
	#
	$self->fileIn ( @_ ) if ( @_ );


	$self->_convert;

}



sub toString
{
my $self = shift;


	#
	# set defaults if unset:
	#
	$self->{sysIn} = new Convert::Ethiopic::System ( "sera" )
		unless ( $self->{sysIn} );

	$self->{sysOut} = new Convert::Ethiopic::System ( "UTF8" )
		unless ( $self->{sysOut} );

	#
	# reset string if we've been passed one:
	#
	$self->fileIn ( @_ ) if ( @_ );


	$self->_toString;

}



sub fileIn
{
my $self = shift;


	$self->{fileIn} = $_[0] if ( @_ );

	$self->{fileIn};
}



sub fileOut
{
my $self = shift;


	$self->{fileOut} = $_[0] if ( @_ );

	$self->{fileOut};
}



sub sysIn
{
my $self = shift;


	$self->{sysIn} = $_[0] if ( @_ );

	$self->{sysIn};
}



sub sysOut
{
my $self = shift;


	$self->{sysOut} = $_[0] if ( @_ );

	$self->{sysOut};
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
