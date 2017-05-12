#!/usr/bin/perl -w

$| =1;

package PerlDemoAdapter;
use base qw( Aw::Adapter );

require Aw;
require Aw::Event;

require HelloWorld;


my ($false, $true) = (0,1);


sub startup {

	my $self = shift;

	#  subscribe to PerlDevKit::PerlDemo
	return $false if ( $self->newSubscription ( "PerlDevKit::PerlDemo", 0 ) );

	#  register the event
	my $event = new Aw::EventType ( "PerlDevKit::PerlDemo" );
	$self->addEvent( $event );

	
	#  set up subscriptions for the Adapter::lookup and Adapter::refresh events
	
	return ( $self->initStatusSubscriptions ) ? $false : $true ;  # init also does publishStatus
    
}


sub processPublication {

	my $self     = shift;
	my $eventDef = shift;

	print "Hello from processPublication Method\n";


	if ( $eventDef->name eq "PerlDevKit::PerlDemo" ) {
		$self->deliverAckReplyEvent;
		return $true;
	}

	print "GoodBye[false] from processPublication Method\n";
	$false;
}



sub processRequest
{
my ($self, $requestEvent, $eventDef) = @_;

	print "Hello from processRequest Method\n";

	my %hash = $requestEvent->toHash;
	print "==============================================\n";
	print "Received:\n";
	print $requestEvent->toString;
	print "==============================================\n";
	print "Executing World Test:\n\n";
	my $world = eval ( $hash{moreData}{structA}{structB}{stringC} );
	$world->run;
	print "==============================================\n";
	$self->deliverAckReplyEvent;

	$true;
}


# =============================================================================#
#  END CALLBACKS SECTION
# =============================================================================#


package main;

main: {

	my %properties 		=(
	        clientId 	=> "Perl Demo Adapter",
	        broker		=> 'test_broker@localhost:6449',
	        adapterId	=> 0,
	        debug		=> 1,
	        clientGroup	=> "PerlDemoAdapter",
	        adapterType	=> "perl_adapter"
	);


	#  Start with one step...
	#
	my $adapter = new PerlDemoAdapter ( \%properties );


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

demo_adapter.pl - An Aw Package Demonstration Client.

=head1 SYNOPSIS

./demo_adapter.pl

=head1 DESCRIPTION

Adapter to handle request for the PerlDevKit::PerlDemo, goes with
the demo_client.pl script.  The adapter simply prints the event it
receives as a string.  It will also deserialize the dumped HelloWorld
object embedded in the event and invoke a method.

The HelloWorld.pm must be installed where both the demo_client.pl
and demo_adapter.pl scripts are executed from.

=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1). ActiveWorks Supplied Documentation>

=cut
