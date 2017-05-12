#!/usr/bin/perl -I. -w

use Aw 'test_broker@localhost:6449';
require Aw::Client;
require Aw::Event;


print "Creating client...\n";
my $client = new Aw::Client ( "devkitClient" );

print "Subscribing to AdapterDevKit::time...\n";
$client->newSubscription ( "AdapterDevKit::time" );

print "Publishing AdapterDevKit::timeRequest...\n";
my $event = new Aw::Event ( $client, "AdapterDevKit::timeRequest" );

$event->setTag ( 1 );
$client->publish ( $event ) and die ( "Publish Error: $!" );


print "Waiting for AdapterDevKit::time...\n";
while ( $event = $client->getEvent( AW_INFINITE ) ) {

	if ( (my $eventTypeName = $event->getTypeName) eq "AdapterDevKit::time" ) {
		my $eventTag = $event->getTag;

		my $date = $event->getDateField ( "time" );
		if ( $eventTag ) {
			printf "Received AdapterDevKit::time reply  %s\n", $date->toString;
		} else {
			printf "Received AdapterDevKit::time update %s\n", $date->toString;
		}
		undef ($eventTag);
		undef ($date);
	} else {
	    	printf "Received \"%s\"\n", $eventTypeName;
	}
	undef ($event);

}

print "done!\n";


__END__

=head1 NAME

time_test.pl - Perlized Version of the CADK Time Client.

=head1 SYNOPSIS

./time_test.pl

=head1 DESCRIPTION

This script is the analog of the ActiveWorks 3.0 and 4.0 ADK
"time_test.c" and "TimeTest.java" clients.  The script is the
counterpart of the time_adapter.pl.

The AdapterDevKit::time, AdapterDevKit::timeRequest and the
devkitClient client group are assumed already set in the target broker.

=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1). ActiveWorks Supplied Documentation>

=cut
