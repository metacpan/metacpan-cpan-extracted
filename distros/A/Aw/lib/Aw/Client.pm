package Aw::Client;


BEGIN
{
	use strict;
	use vars qw($VERSION);

	$VERSION = '0.3';

	use Aw;
}


sub new
{

	return ( Aw::Client::_new ( @_ ) ) if ( @_ > 3 );

	my ($class, $client_group)  = @_;
	my $app_name = (@_ == 3) ? $_[2] : $0.".Client";

	Aw::Client::_new ( $class, $Aw::DefaultBrokerHost, $Aw::DefaultBrokerName, "", $client_group, $app_name );

}



sub newOrReconnect
{

	return ( Aw::Client::_newOrReconnect ( @_ ) ) if ( @_ > 3 );

	my ($class, $client_group)  = @_;
	my $app_name = (@_ == 3) ? $_[2] : $0.".Client";

	Aw::Client::_newOrReconnect ( $class, $Aw::DefaultBrokerHost, $Aw::DefaultBrokerName, "", $client_group, $app_name );

}



sub connect
{
my %config = ( ref $_[0] ) #  Reference?
           ?  %{$_[0]}        # Yes.
           : @_               # No.
           ;

	unless ( $config{clientGroup} ) {
		CORE::warn ( "Client Group is undefined." );		
		return undef;
	}


	$config{brokerHost} = $Aw::DefaultBrokerHost unless ( $config{brokerHost} );
	$config{brokerName} = $Aw::DefaultBrokerName unless ( $config{brokerName} );
	$config{clientId}   = ""                     unless ( $config{clientId} );
	$config{applicationName} = $0.".Client"      unless ( $config{applicationName} );
	$config{connectionDescriptor} = 0            unless ( $config{connectionDescriptor} );


        my $c = new Aw::Client ( $config{brokerHost}, $config{brokerName}, $config{clientId}, $config{clientGroup}, $config{applicationName}, $config{connectionDescriptor} );

	unless ( $c || !$config{clientId} ) {
		if ( Aw::Error::getCode == AW_ERROR_CLIENT_EXISTS ) {
			$c = _reconnect Aw::Client ( $config{brokerHost}, $config{brokerName}, $config{clientId} );
			unless ( $c ) {
				print STDERR "Could not reconnect.\n";
				print STDERR Aw::Error::toString, "\n";
			}
		} else { 
			print STDERR "Could not create client!\n";
			print STDERR Aw::Error::toString, "\n";
		}
	}        
         

        $c;
}



sub reconnect
{

	return ( Aw::Client::_reconnect ( @_ ) ) if ( @_ > 1 );
	
	my ($class)  = $_[0];
	my ($bHost, $bName, $clientId)
	    = ($class->getBrokerHost.":".$class->getBrokerPort, $class->getBrokerName, $class->getClientId);

	Aw::Client::_reconnect ( $class, $bHost, $bName, $clientId );

}



sub deliverReplyEvent
{
my $self = shift;

	( ref ($_[0]) )
	  ? $self->deliverReplyEvents ( $_[0] )
	  : ( @_ > 1 )
	    ? $self->deliverReplyEvents ( \@_ )
	    : $self->_deliverReplyEvent ( $_[0] )
	;

}



sub deliverRequestAndWait
{
	my $result = Aw::Client::deliverRequestAndWaitRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getAccessLabel
{
	my $result = Aw::Client::getAccessLabelRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getCanPublishNames
{
	my $result = Aw::Client::getCanPublishNamesRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getCanPublishTypeDefs
{
	my $result = Aw::Client::getCanPublishTypeDefsRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getCanSubscribeNames
{
	my $result = Aw::Client::getCanSubscribeNamesRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getSubscriptions
{
	my $result = Aw::Client::getSubscriptionsRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getEvents
{
	my $result = Aw::Client::getEventsRef ( @_ ) or return ( undef );
	( wantarray ) ? @{ $result } : $result ;
}



sub getEventTypeDefs
{
	my $result = Aw::Client::getEventTypeDefsRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getEventTypeNames
{
	my $result = Aw::Client::getEventTypeNamesRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getEventTypeInfosetNames
{
	my $result = Aw::Client::getEventTypeInfosetNamesRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getFamilyNames
{
	my $result = Aw::Client::getFamilyNamesRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getFamilyEventTypeNames
{
	my $result = Aw::Client::getFamilyEventTypeNamesRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getScopeNames
{
	my $result = Aw::Client::getScopeNamesRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getScopeEventTypeNames
{
	my $result = Aw::Client::getScopeEventTypeNamesRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub getPlatformInfoKeys
{
	my $result = Aw::Client::getPlatformInfoKeysRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub publishEventsWithAck
{
	unless ( ref($_[1]) eq "ARRAY" ) {
		CORE::warn ( "arg 0 is not an array reference." );
		return undef;
	}
	unless ( ref($_[3]) eq "ARRAY") {
		CORE::warn ( "arg 2 is not an array reference." );
		return undef;
	}

	Aw::Client::_publishEventsWithAck ( @_ );
}



sub deliverEventsWithAck
{
	unless ( ref($_[2]) eq "ARRAY") {
		CORE::warn ( "arg 0 is not an array reference." );
		return undef;
	}
	unless ( ref($_[4]) eq "ARRAY") {
		CORE::warn ( "arg 2 is not an array reference." );
		return undef;
	}

	Aw::Client::_deliverEventsWithAck ( @_ );
}



sub publishRequestAndWait
{
	my $result = Aw::Client::publishRequestAndWaitRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



sub cancelSubscriptions
{
my $self = shift;

	( ref ($_[0]) eq "ARRAY" ) # we _want_ to send array elements
	  ? $self->_cancelSubscriptions ( @{$_[0]} )
	  : $self->_cancelSubscriptions ( @_ )
	;
}



sub cancelSubscription
{
my $self = shift;

	( ref ($_[0]) ) # we _want_ to send array elements
	  ? $self->_cancelSubscriptions ( @_ )
	  : $self->_cancelSubscription ( @_ )
	;
}



sub beginTransaction
{
my ( $self, $transaction_id, $required_level ) = ( shift, shift, shift );

	( ref ($_[0]) )
	  ? $self->_beginTransaction ( $transaction_id, $required_level, $_[0] )
	  : $self->_beginTransaction ( $transaction_id, $required_level, \@_ )
	;
}



sub newSubscriptions
{
my $self = shift;
my $filter = ( $_[$#_] =~ /(([-=<>&|^\/%*~])|( and )|( or ))/ ) ? pop @_ : 0 ;
my $retVal = 0;  # awaFalse => no error


	if ( ref ($_[0]) eq "ARRAY" ) {
		while ( $_ = shift @{$_[0]} ) {
	   		$retVal = $self->_newSubscription ( $_  , $filter );
			last if ( $retVal );
		}
	} elsif ( ref ($_[0]) eq "HASH" ) {
		for $_ (values %{$_[0]} ) {
	   		$retVal = $self->_newSubscription ( $_  , $filter );
			last if ( $retVal );
		}
	} else {
		while ( $_ = shift @_ ) {
	   		$retVal = $self->_newSubscription ( $_  , $filter );
			last if ( $retVal );
		}
	}

	$retVal;
}



sub newSubscription
{
	newSubscriptions ( @_ );
}



sub getEventTypeInfosets
{
	my $result = Aw::Client::getEventTypeInfosetsRef ( @_ );
	( wantarray ) ? @{ $result } : $result ;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__

=head1 NAME

Aw::Client - ActiveWorks Client Module.

=head1 SYNOPSIS

require Aw::Client;

my $client = new Aw::Client ( @args );


=head1 DESCRIPTION

Enhanced interface for the Aw.xs Client methods.


=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1).  Aw(3).>

=cut
