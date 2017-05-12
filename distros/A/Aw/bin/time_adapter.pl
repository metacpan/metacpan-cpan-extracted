#!/usr/bin/perl -I. -w

package TimeAdapter;
use base qw( Aw::Adapter );

require Aw;
require Aw::Event;


my ($false, $true) = (0,1);

#  for use in the AdapterDevKit::time event
my $eventTime = new Aw::Date;   # should be empty and must be in the
                                # scope of startup and createTimeEvent



sub startup {

	my $self = shift;

	#  subscribe to AdapterDevKit::timeRequest 
	return $false if ( $self->newSubscription ( "AdapterDevKit::timeRequest", 0 ) );


	#  register the event
	$self->addEvent( new Aw::EventType ( "AdapterDevKit::timeRequest" ) );

	
	if ( $self->isMaster ) {
	 	#  set up the periodic publication of AdapterDevKit::time
		my $event = new Aw::EventType ( "AdapterDevKit::time" );
	 	$event->isPublish ( $true );
	 	$event->publishInterval ( 15 );
	 	$event->nextPublish ( time );

		#  set the pubish time to fall onto an "even" time
	 	$event->nextPublish ( ($event->nextPublish + $event->publishInterval - ($event->nextPublish % $event->publishInterval)) );
	 	$self->addEvent ( $event );
	}
    
	#  set up subscriptions for the Adapter::lookup and Adapter::refresh events
	
	( $self->initStatusSubscriptions ) ? $false : $true ;  # init also does publishStatus
    
}


#
#  A subroutine used by the call backs
#
sub createTimeEvent {

	my $self = shift;
	my $event;

	return (undef)
		unless ( $event = $self->createEvent ( "AdapterDevKit::time" ) );

	$eventTime->setDateCtime ( time );

	$event->setDateField ( "time", $eventTime );

	$event;
}



# =============================================================================#
#
#  Call backs are written here.
#
#    adapter->processPublicationFunction = processPublication
#    adapter->processRequestFunction     = processRequest
#
# =============================================================================#

#
#  We schedule the next publication ourselves, and therefore, return $true.
#  Must return a boolean:  Adapter DK 6-44
#
sub processPublication {

	my $self     = shift;
	my $eventDef = shift;

	print "Hello from processPublication Method\n";


	if ( $eventDef->name eq "AdapterDevKit::time" ) {
		$eventDef->nextPublish ( $eventDef->nextPublish + $eventDef->publishInterval );

		my $reply = $self->createTimeEvent;

		return $true unless ( $reply );
	
		$self->publish ( $reply );
		undef ($reply);		 #  Forced because the Perl 5.004_4 gargabe collector misses this.
		# print "GoodBye[true] from processPublication Method\n";
		return $true;
	}

	# print "GoodBye[false] from processPublication Method\n";
	$false;
}



#
# callback to process a request:  Adapter DK 6-45
#
sub processRequest {

	my ( $self, $reqEvent, $eventDef ) = @_;

	# print "Hello from processRequest Method\n";

	my $reply = $self->createTimeEvent ( $self );

	$self->deliverReplyEvent ( $reply ) if ( $reply );
	
	$true;
}

# =============================================================================#
#  END CALLBACKS SECTION
# =============================================================================#



package main;

main: {

	#
	# traditional style (use awAdapterLoadProperties):
	#
	my @properties =(
	        'TimeAdapter',
	        'test_broker@localhost:6449',
	        0,
	        # './adapters.cfg', # required if not in the system adapters.cfg
	        'debug=1',
	        'clientGroup=devkitAdapter',
	        'adapterType=Adapter40',
	        'messageCatalog=time_adapter'
	);
	#
	#  or use a hash!  no .cfg file needed:
	#
	my %properties		=(
	        clientId	=> 'TimeAdapter',
	        broker		=> 'test_broker@localhost:6449',
	        adapterId	=> 0,
	        debug		=> 1,
	        clientGroup	=> 'devkitAdapter',
	        adapterType	=> 'Adapter40',
	        messageCatalog	=> 'time_adapter'   # optional
		# configFile	=> '/path/to/file'  # optional
	);


	#  Start with one step...
	#
	my $adapter = new TimeAdapter ( \%properties );
	# my $adapter = new TimeAdapter ( \@properties );


	#
	# Alternately, two steps...
	#
	# $adapter = new TimeAdapter;
	# $adapter->loadProperties ( @properties );


	my $retVal = 0;

	#  process connection testing mode 
	#
	die ( "\n$retVal = ", $adapter->connectTest, "\n" )
		if ( $adapter->isConnectTest );


	if ( $adapter->createClient ) {
  		# we don't want to go here.
		$retVal = 1;
	} else {
		# we want to go here

		$retVal = $adapter->startup;

		my $test = $adapter->getEvents;

		$retVal = 1 if ($retVal && $adapter->getEvents);
	}


	print "\nRetval = $retVal\n";
}

__END__

=head1 NAME

time_adapter.pl - Perlized Version of the CADK Time Adapter.

=head1 SYNOPSIS

./time_adapter.pl

=head1 DESCRIPTION

This script is the analog of the ActiveWorks 3.0 and 4.0 ADK
"time_adapter.c" and "TimeAdapter.java" adapters.  The script is the
counterpart of the time_test.pl script.

The AdapterDevKit::time, AdapterDevKit::timeRequest and the
devkitAdapter client group are assumed already set in the target broker.

=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1). ActiveWorks Supplied Documentation>

=cut
