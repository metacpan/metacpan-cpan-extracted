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

	my $terr  = $c->getTerritoryInfo;
	print "Territory: $terr->{territory_name}\n";
	print "  auth_type    : $terr->{auth_type}\n";
	print "  encrypt_level: $terr->{encrypt_level}\n";

        $terr = $c->getTerritoryStats->toHash;

	my @brokers = @{ $terr->{brokers} };       # all brokers not including connected to 
  	foreach ( @brokers ) {
		my $bstats = $_;
		print "\n";
		print "  $bstats->{brokerName}\@$bstats->{brokerHost}";
		print " ($bstats->{description})" if ( $bstats->{description} );
		print "\n";
		delete ( $bstats->{brokerHost} );
		delete ( $bstats->{brokerName} );
		delete ( $bstats->{description} );

		foreach ( sort keys %$bstats ) {
			if ( ref($bstats->{$_}) eq "Aw::Date" ) {
				print "    $_ => ", $bstats->{$_}->toString, "\n";
			}
			else {
				print "    $_ => $bstats->{$_}\n";
			}
		}
		$bstats = undef;
	}



        @brokers = $c->getBrokersInTerritory;  # all brokers

  foreach ( @brokers ) {
	print "\n";
	my $broker = $_;
	print "Broker: $broker->{broker_name}\@$broker->{broker_host}";
	print " ($broker->{description})" if ( $broker->{description} );
	print "\n";

	$c = undef;
	$c = new Aw::Admin::Client ( $broker->{broker_host}, $broker->{broker_name}, "", $client_group, "Client Finger" )
	  || die "Error connecting to broker.\n";  # specific error message should have been echoed

	my %stats = $c->getBrokerStats->toHash;
	delete ( $stats{_name} );
	foreach ( sort keys %stats ) {
		if ( ref($stats{$_}) eq "Aw::Date" ) {
			print "  $_ => ", $stats{$_}->toString, "\n";
		}
		else {
			print "  $_ => $stats{$_}\n";
		}
	}
	print "\n";

  foreach ( $c->getClientIds ) {
	print "$_\n";

	my $info  = $c->getClientInfoById ( $_ );
	my %stats = $c->getClientStatsById ( $_ )->toHash;
	my @subs  = $c->getClientSubscriptionsById ( $_ );

	foreach ( sort keys %$info ) {
		if ( /^sessions/ ) {
			next unless ( $info->{num_sessions} );
			my $sessions = $info->{sessions};
			print "  sessions[$info->{num_sessions}] {\n";
			my $i = 0;
			foreach (@{$sessions}) {
				print "    session[", $i++, "] {\n";
				my $session = $_;
				foreach ( sort keys %$session ) {
					if ( /^platform_info/ ) {
						my $platform = $session->{$_};
						foreach ( keys %$platform ) {
							print "      $_ => $platform->{$_}\n";
						}
					}
					elsif ( /^ip_address/ ) {
							# sprintf ("%d.%d.%d.%d", unpack ('C4', pack ('l4', $_[0]) ) );
							# print "      $_ => ", unpack_ip ( $session->{$_} ), "\n";
							printf ("      $_ => %d.%d.%d.%d\n", unpack ('C4', pack ('l4', $session->{$_}) ) );
					}
					elsif ( ref($session->{$_}) eq "Aw::Date" ) {
						print "      $_ => ", $session->{$_}->toString, "\n";
					}
					elsif ( ref($session->{$_}) eq "Aw::SSLCertificate" ) {
						my $ssl = $session->{$_}->toIndentedString(0);
						$ssl =~ s/\n//;
						$ssl =~ s/^/      /mg;
						print $ssl, "\n";
					}
					elsif ( !/num_/ ) {
						print "      $_ => $session->{$_}\n";
					}
				}
				if ( $i < $info->{num_sessions} ) {
					print "    },\n";
				}
				else {
					print "    }\n";
				}
			}
			print "  };\n";
		}
		elsif ( ref($info->{$_}) eq "CORBA::LongLong" ) {
			print "  $_ => ", int $info->{$_}, "\n"; # this may not really be longlong
		}
		elsif ( !/num_/ && !/^_/ ) {
			print "  $_ => $info->{$_}\n";
		}
	}
	delete ( $stats{_name} );
	foreach ( sort keys %stats ) {
		if ( ref($stats{$_}) eq "Aw::Date" ) {
			print "  $_ => ", $stats{$_}->toString, "\n";
		}
		else {
			print "  $_ => $stats{$_}\n";
		}
	}
	if (@subs) {
		print "  Subscribed To:\n";
		foreach ( @subs ) {
		 	print "    ", $_->getEventTypeName, "\n";
		}
	}

  }  # end foreach ( $c->getClientIds )

  } # end  foreach ( @brokers )

}

__END__

=head1 NAME

terr_finger.pl - Finger Territory Clients.

=head1 SYNOPSIS

./terr_finger.pl MyBroker@MyHost:1234

=head1 DESCRIPTION

Get all possibly info available on a territory and every connected
element on every broker in the territory.  Except for gateways
since I've never had one to work with.

The localhost is used when no host is provided after "@".
The default broker is used when no broker is specified.

=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1). ActiveWorks Supplied Documentation>

=cut
