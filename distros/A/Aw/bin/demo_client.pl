#!/usr/bin/perl -w

use Aw;
require Aw::Adapter;
require Aw::Client;
require Aw::Event;

require HelloWorld;
use Data::Dumper;

my $EXIT_FAILURE = 1;

my ($false, $true) = (0,1);


sub MyDumper
{
	$_ = Dumper ( $_[0] );
	s/^(.*?)bless/bless/;
	$_;
}



sub getResponse
{
my $c = shift;

	my $e = $c->getEvent ( AW_INFINITE );

	unless ( $e ) {
		printf STDERR "%s\n", $c->errmsg;
		exit ( $EXIT_FAILURE );
	}

	my $eventName = $e->getTypeName; 
	print STDERR "Received an $eventName event\n";

	if ( $eventName eq "Adapter::ack" ) {
		#
		# awGetFieldNames used in the toHash method does not
		# get the _env field (not that we normally want it),
		# but we can still extract it like so:
		#
		my %eventData = $e->getField ( "_env" );

		foreach my $key (sort keys %eventData) {
			if ( ref($eventData{$key}) eq "Aw::Date" ) {
				print STDERR "  $key => ", $eventData{$key}->toString, "\n";
			}
			else {
				print STDERR "  $key => $eventData{$key}\n";
			}
		}
	} else {
		print STDERR $e->toString;
	}

}



main:
{
my %Config 		=(
	# Adapter configuration structure.
	brokerName	=> 'test_broker',	#  Name of the broker.
	brokerHost 	=> 'localhost:6449',	#  FQDN of the broker host.
	clientGroup	=> 'PerlDemoClient',	#  Client group we're in.
	clientName	=> 'PerlDemo',		#  Name of client, for queueing.
	application	=> 'PerlDemo',		#  The application's name.
	adapterName	=> 'Perl Demo Adapter' 	#  The application's name.
);

my @arrayData = ( 'A', 'B', 'C' );
my %hashData  = ( structInt => 11, structString => "Hello From Struct B" );

my %FieldData 		=(
    booleanDemo		=>	$false,
    charDemo		=>	'Z',
    # dateDemo		=>	'2000-1-10',
    floatDemo,		=>	123.456,
    intDemo,		=>	123456,
    stringDemo		=>	"Hello World",
    stringSeqDemo	=>	[ "One", "Two", "Three" ],
    intSeqDemo		=>	[10,20,30,40,50],
    charSeqDemo		=>	\@arrayData,
    structADemo		=>	{ structInt => 99, structString => "Hello From Struct A" },
    structBDemo		=>	\%hashData,
    structCDemo		=>	{
					# charSeqDemo	=> \@arrayData
					# charSeqDemo	=> [ 'X', 'Y', 'Z' ]
					intSeqDemo	=> [ 1, 2, 3, 4, 5 ]
					# structInt	=> 33,
					# structString 	=> "Hello From Struct C"
				},
    structDDemo		=>	{
					structInt	=> 55,
					structADemo	=> { 
								structInt => 11,
								structString => "Hello From StructD:A"
							   } 
				}
);

%MoreData 	=(
	intA	=> 11,
	structA	=> {
		intB	=> 22,
		structB	=> { 
			intC	=> 33,
			stringC	=> "Hello From StructB"
		} 
	}
);


	my $eventName = "PerlDevKit::PerlDemo";

	my $world = new HelloWorld;
	$world->store(5);
	$MoreData{structA}{structB}{stringC} = MyDumper ( $world );
	undef ( $world );

	my $eventTime = new Aw::Date;
	$eventTime->setDateCtime ( time );
	$FieldData{dateDemo} = $eventTime;

	$FieldData{moreData} = \%MoreData;


	#  Create the client object, and check if we can publish to the
	#  supplied event.
	#
	# my $c = connect Aw::Client ( \%Config );
	my $c = Aw::Client::connect  ( \%Config );
	
	
	unless ( $c->canPublish ( $eventName ) ) {
		printf STDERR "Cannot publish to %s: %s\n", $eventName, $c->errmsg;
		exit ( $EXIT_FAILURE );
	}


	#  Create a new broker Event.
	#
	my $e = new Aw::Event ( $c, $eventName, \%FieldData );
	# my $e = new Aw::Event ( $c, $eventName );  # two step approach

	unless ( $e ) {	
		print STDERR $e->errmsg, "\n";
		exit ( $EXIT_FAILURE );
	}

	# or if event is created in two steps:
	#
	# $e->init ( \%FieldData );


	#  Now that all event strings are set, publish the event to
	#  the broker.
	#  Then display the event as text once published.
	#
	if ( $c->deliver ( $Config{adapterName}, $e ) ) {
		print STDERR $c->errmsg;
		exit ( $EXIT_FAILURE );
	} else {
		print "Published a $eventName event.\n";
		print $e->toString, "\n";
	}

	getResponse ( $c );

	exit ( 0 );
}

__END__

=head1 NAME

demo_client.pl - An Aw Package Demonstration Adapter.

=head1 SYNOPSIS

./demo_client.pl

=head1 DESCRIPTION

Client to submit the PerlDevKit::PerlDemo event, goes with
the demo_adapter.pl script.  The adapter simply prints the event it
receives as a string.  The script demonstrates client and event
creation for a modestly complex event.  The script will also create,
dump (serialize) and embed a HelloWorld object that the adapter will revive.

The HelloWorld.pm must be installed where both the demo_client.pl
and demo_adapter.pl scripts are executed from.

=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1). ActiveWorks Supplied Documentation>

=cut
