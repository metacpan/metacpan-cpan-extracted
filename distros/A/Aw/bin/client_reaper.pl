#!/usr/bin/perl -w

use strict;

require Aw::Admin::Client;
require Aw::Event;


main: {

	my ( $broker_name, $broker_host );
	( $broker_name, $broker_host ) = split ( /\@/, $ARGV[0] ) if ( @ARGV );

	$broker_host ||= "localhost";  # use default broker on default server
	$broker_name ||= "";           # to avoid undefined warning at $c = new

	my $client_group = "admin";

	my $c = new Aw::Admin::Client ( $broker_host, $broker_name, "", $client_group, "Client Finger" )
	     || die "Error connecting to broker.\n";  # specific error message should have been echoed

        my @brokers = $c->getBrokersInTerritory;  # all brokers

	foreach ( @brokers ) {
		my $broker = $_;

		my $c = new Aw::Admin::Client ( $broker->{broker_host}, $broker->{broker_name}, "", $client_group, "Client Reaper" )
		     || die "Error connecting to broker.\n";  # specific error message should have been echoed

		foreach ( $c->getClientIds ) {
			my $info  = $c->getClientInfoById ( $_ );
			unless ( $info->{num_sessions} ) {
			 	$c->disconnectClientById ( $_ );
			 	$c->destroyClientById ( $_ );
			}
		}  # end foreach ( $c->getClientIds )

	} # end  foreach ( @brokers )

}

__END__

=head1 NAME

client_reaper.pl - Delete Sessionless Clients in a Territory.

=head1 SYNOPSIS

./client_reaper.pl MyBroker@MyHost:1234

=head1 DESCRIPTION

Crawl the territory of the broker given in the "MyBroker@MyHost:1234" argument
and delete all sessionless clients.

The localhost is used when no host is provided after "@".
The default broker is used when no broker is specified.

=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1). ActiveWorks Supplied Documentation>

=cut
