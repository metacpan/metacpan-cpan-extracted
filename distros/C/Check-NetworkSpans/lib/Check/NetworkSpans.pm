package Check::NetworkSpans;

use 5.006;
use strict;
use warnings;
use Rex::Commands::Gather;
use Regexp::IPv4 qw($IPv4_re);
use Regexp::IPv6 qw($IPv6_re);
use Scalar::Util qw(looks_like_number);
use File::Temp   qw/ tempdir /;
use String::ShellQuote;
use JSON;
use Data::Dumper;

=head1 NAME

Check::NetworkSpans - See if bidirectional traffic is being seen on spans.

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';

=head1 SYNOPSIS

    use Check::NetworkSpans;

    my $span_checker = Check::NetworkSpans->new(
            spans=>[
                   ['em0', 'em1'],
                   ['em2', 'em3'],
                   ],
            low_packets_to_ignore=>['em2,em3'],
        );

=head1 METHODS

=head2 new

Initiates the object.

    - spans :: A array of arrays. Each sub array is a list of interfaces
            to check. If not defined it will check all interfaces and treat
            them as one span.
        - Default :: undef

    - ignore_IPs :: A array of IPs to ignore.
        - Default :: undef

    - auto_ignore :: If true, then will ignore all IP on that machine. Only
            for the first IP of the interface.
        - Default :: 1

    - packets :: Number of packets to gather for a interface for checking.
        - Default :: 5000

    - duration :: Number of seconds to limit the run to.
        - Default :: 60

    - ports :: Common ports to look for. Anything here will override the defaults.
        - Default :: [ 22, 53, 80, 88, 135, 389, 443, 445, 3389, 3306, 5432 ]

    - additional_ports :: Additional ports to look for.
        - Default :: [ ]

    - span_names :: Optional name for spans. Name corresponds to index of spans array.
        - Default :: [ ]

    my $span_checker = Check::NetworkSpans->new(
        spans                       => \@spans,
        ignore_IPs                  => \@ignore_IPs,
        auto_ignore                 => $auto_ignore,
        packets                     => $packets,
        duration                    => $duration,
        ports                       => \@ports,
        additional_ports            => \@additional_ports,
		no_packets                  => 2,
		no_packets_to_ignore        => {},
		low_packets                 => 1,
		low_packets_to_ignore       => {},
		no_streams                  => 2,
		no_streams_to_ignore        => {},
		missing_interface           => 3,
		missing_interface_to_ignore => {},
    );

Below are the options controlling alerting and what to ignore.

    - no_packets :: If the span has no packets.
        Value :: alert level
        Default :: 2

    - no_packets_to_ignore ::
        Value :: array of spans or span names
        Default :: []

    - low_packets :: If the span has fewer packets than the amount specified by packets.
        Value :: alert level
        Default :: 1

    - low_packets_to_ignore :: What to ignore for low_packets.
        Value :: array of spans or span names
        Default :: []

    - no_streams :: No bidirectional TCP/UDP streams were found between IP addresses.
        Value :: alert level
        Default :: 2

    - no_streams_to_ignore :: What to ignore for no_streams.
        Value :: array of spans or span names
        Default :: []


    - missing_interface :: A interface is missing.
        Value :: alert level
        Default :: 3

    - missing_interface_to_ignore :: What to ignore for missing_interface.
        Value :: array interfaces
        Default :: []

    - port_check :: No traffic was found on the expected ports.
        Value :: alert level
        Default :: 1

    - port_check_to_ignore :: What to ignore for port_check.
        Value :: array of spans or span names
        Default :: []

Levels are as below.

    - 0 :: OK
    - 1 :: WARNING
    - 2 :: ALERT
    - 3 :: ERROR

=cut

sub new {
	my ( $blank, %opts ) = @_;

	# ensure spans is defined and an array
	if ( !defined( $opts{spans} ) ) {
		die('"spans" is undef');
	} elsif ( ref( $opts{spans} ) ne 'ARRAY' ) {
		die( '"spans" is defined and is ref "' . ref( $opts{spans} ) . '" instead of ARRAY' );
	}

	my $self = {
		ignore_IPs                  => [],
		spans                       => [],
		interfaces                  => [],
		packets                     => 5000,
		duration                    => 60,
		warnings                    => [],
		ports                       => [],
		ports_check                 => {},
		span_names                  => [],
		no_packets                  => 2,
		no_packets_to_ignore        => {},
		low_packets                 => 1,
		low_packets_to_ignore       => {},
		no_streams                  => 2,
		no_streams_to_ignore        => {},
		down_interface              => 2,
		down_interfaces_to_ignore   => {},
		missing_interface           => 3,
		missing_interface_to_ignore => {},
		interfaces_missing          => [],
		interfaces_down             => {},
		port_check                  => 1,
		port_check_to_ignore        => {},
		debug                       => $opts{debug},
	};
	bless $self;

	# suck in alert handling stuff
	my @alerts = ( 'no_packets', 'low_packets', 'no_streams', 'down_interface', 'missing_interface', 'port_check' );
	foreach my $alert_type (@alerts) {
		if ( defined( $opts{$alert_type} ) ) {
			if ( ref( $opts{$alert_type} ) ne '' ) {
				die( '$opts{' . $alert_type . '} should be ref "" and not ' . ref( $opts{$alert_type} ) );
			}
			if (   $opts{$alert_type} ne '0'
				&& $opts{$alert_type} ne '1'
				&& $opts{$alert_type} ne '2'
				&& $opts{$alert_type} ne '3' )
			{
				die( '$opts{' . $alert_type . '} should be either 0, 1, 2, or 3 and not ' . $opts{$alert_type} );
			}
			$self->{$alert_type} = $opts{$alert_type};

		} ## end if ( defined( $opts{$alert_type} ) )
		if ( defined( $opts{ $alert_type . '_to_ignore' } ) ) {
			if ( ref( $opts{ $alert_type . '_to_ignore' } ) ne 'ARRAY' ) {
				die(      '$opts{'
						. $alert_type
						. '_to_ignore} should be ref ARRAY and not '
						. ref( $opts{ $alert_type . '_to_ignore' } ) );
			}
			foreach my $to_ignore ( @{ $opts{ $alert_type . '_to_ignore' } } ) {
				$self->{ $alert_type . '_to_ignore' }{$to_ignore} = 1;
			}
		} ## end if ( defined( $opts{ $alert_type . '_to_ignore'...}))
	} ## end foreach my $alert_type (@alerts)

	# get span_names and ensure it is a array
	if ( defined( $opts{span_names} ) && ref( $opts{span_names} ) eq 'ARRAY' ) {
		$self->{span_names} = $opts{span_names};
	} elsif ( defined( $opts{span_names} ) && ref( $opts{span_names} ) ne 'ARRAY' ) {
		die( '$opts{span_names} ref is not ARRAY, but "' . ref( $opts{span_names} ) . '"' );
	}

	# get packet info and do a bit of sanity checking
	if ( defined( $opts{packets} ) && looks_like_number( $opts{packets} ) ) {
		if ( $opts{packets} < 1 ) {
			die( '$opts{packets} is ' . $opts{packets} . ' which is less than 1' );
		}
		$self->{packets} = $opts{packets};
	} elsif ( defined( $opts{packets} ) && !looks_like_number( $opts{packets} ) ) {
		die('$opts{packets} is defined and not a number');
	}

	# if ports is set, ensure it is a array and if so process it
	if ( defined( $opts{ports} ) && ref( $opts{ports} ) ne 'ARRAY' ) {
		die( '"ports" is defined and is ref "' . ref( $opts{ports} ) . '" instead of ARRAY' );
	} elsif ( defined( $opts{ports} ) && ref( $opts{ports} ) eq 'ARRAY' && defined( $opts{ports}[0] ) ) {
		foreach my $port ( @{ $opts{ports} } ) {
			if ( ref($port) ne '' ) {
				die( 'Values for the array ports must be ref type ""... found "' . ref($port) . '"' );
			} elsif ( !looks_like_number($port) ) {
				die(      'Values for the array ports must be numberic... found "'
						. $port
						. '", which does not appear to be' );
			}
			push( @{ $self->{ports} }, $port );
		} ## end foreach my $port ( @{ $opts{ports} } )
	} else {
		# defaults if we don't have ports
		push( @{ $self->{ports} }, 22, 53, 80, 88, 135, 389, 443, 445, 3389, 3306, 5432 );
	}

	# if additional_ports is set, ensure it is a array and if so process it
	if ( defined( $opts{additional_ports} ) && ref( $opts{additional_ports} ) ne 'ARRAY' ) {
		die( '"additional_ports" is defined and is ref "' . ref( $opts{additional_ports} ) . '" instead of ARRAY' );
	} elsif ( defined( $opts{additional_ports} )
		&& ref( $opts{additional_ports} ) eq 'ARRAY'
		&& defined( $opts{additional_ports}[0] ) )
	{
		foreach my $port ( @{ $opts{additional_ports} } ) {
			if ( ref($port) ne '' ) {
				die( 'Values for the array additional_ports must be ref type ""... found "' . ref($port) . '"' );
			} elsif ( !looks_like_number($port) ) {
				die(      'Values for the array additional_ports must be numberic... found "'
						. $port
						. '", which does not appear to be' );
			}
			push( @{ $self->{ports} }, $port );
		} ## end foreach my $port ( @{ $opts{additional_ports} })
	} ## end elsif ( defined( $opts{additional_ports} ) &&...)

	if ( defined( $opts{duration} ) && looks_like_number( $opts{duration} ) ) {
		$self->{duration} = $opts{duration};
	}

	my $interfaces = network_interfaces;
	# make sure each specified interface exists
	foreach my $span ( @{ $opts{spans} } ) {
		if ( ref($span) ne 'ARRAY' ) {
			die( 'Values for spans should be a array of interface names... not ref "' . ref($span) . '"' );
		}
		my $new_span = [];
		if ( defined( $span->[0] ) ) {
			foreach my $interface ( @{$span} ) {
				if ( ref($interface) ne '' ) {
					die( 'interface values in span must be of ref type "" and not ref ' . ref($interface) );
				} elsif ( !defined( $interfaces->{$interface} ) ) {
					push( @{ $self->{interfaces_missing} }, $interface );
				} else {
					push( @{ $self->{interfaces} }, $interface );
					push( @{$new_span},             $interface );
				}
			} ## end foreach my $interface ( @{$span} )
		} ## end if ( defined( $span->[0] ) )

		push( @{ $self->{spans} }, $new_span );
	} ## end foreach my $span ( @{ $opts{spans} } )

	# ensure all the ignore IPs are actual IPs
	if ( defined( $opts{ignore_IPs} ) ) {
		if ( ref( $opts{ignore_IPs} ) ne 'ARRAY' ) {
			die( '"ignore_IPs" is defined and is ref "' . ref( $opts{ignore_IPs} ) . '" instead of ARRAY' );
		}

		foreach my $ip ( @{ $opts{ignore_IPs} } ) {
			if ( $ip !~ /^$IPv6_re$/ && $ip !~ /^$IPv4_re$/ ) {
				die( '"' . $ip . '" does not appear to be a IPv4 or IPv6 IP' );
			}
			push( @{ $self->{ignore_IPs} }, $ip );
		}
	} ## end if ( defined( $opts{ignore_IPs} ) )

	if ( $opts{auto_ignore} ) {
		foreach my $interface ( keys( %{$interfaces} ) ) {
			if (
				defined( $interfaces->{$interface}{ip} )
				&& (   $interfaces->{$interface}{ip} =~ /^$IPv6_re$/
					|| $interfaces->{$interface}{ip} =~ /^$IPv4_re$/ )
				)
			{
				push( @{ $self->{ignore_IPs} }, $interfaces->{$interface}{ip} );
			}
		} ## end foreach my $interface ( keys( %{$interfaces} ) )
	} ## end if ( $opts{auto_ignore} )

	# put together list of ports to help
	foreach my $ports ( @{ $self->{ports} } ) {
		$self->{ports_check}{$ports} = 1;
	}

	return $self;
} ## end sub new

=head2 check

Runs the check. This will call tshark and then disect that captured PCAPs.

    my $results = $span_checker->check;

    use Data::Dumper;
    print Dumper($results);

The returned value is a hash. The keys are as below.

    - oks :: An array of items that were considered OK.

    - warnings :: An array of items that were considered warnings.

    - criticals :: An array of items that were considered criticals.

    - ignored :: An array of items that were ignored.

    - status :: Alert status integer.

=cut

sub check {
	my $self = $_[0];

	my $filter = '';
	if ( $self->{ignore_IPs}[0] ) {
		if ( $self->{debug} ) {
			print "DEBUG: Processing \$self->{ignore_IPs} ...\n";
		}
		my $ignore_IPs_int = 0;
		while ( defined( $self->{ignore_IPs}[$ignore_IPs_int] ) ) {
			if ( $ignore_IPs_int > 0 ) {
				$filter = $filter . ' and';
			}
			$filter = $filter . ' not host ' . $self->{ignore_IPs}[$ignore_IPs_int];

			$ignore_IPs_int++;
		}
		$filter =~ s/^ //;
		if ( $self->{debug} ) {
			print 'DEBUG: Finished generating filter... filter=' . $filter . "\n";
		}
	} ## end if ( $self->{ignore_IPs}[0] )

	my $dir = tempdir( CLEANUP => 1 );
	chdir($dir);

	my @span_names;
	foreach my $span ( @{ $self->{spans} } ) {
		my $span_name = join( ',', @{$span} );
		push( @span_names, $span_name );
		my @tshark_args = (
			'tshark',                      '-a', 'duration:' . $self->{duration}, '-a',
			'packets:' . $self->{packets}, '-w', $span_name . '.pcap',            '-f',
			$filter
		);
		foreach my $interface ( @{$span} ) {
			push( @tshark_args, '-i', $interface );
		}
		if ( $self->{debug} ) {
			print 'DEBUG: calling tshark for span '
				. $span_name
				. "\nDEBUG: args... '"
				. join( '\' ', @tshark_args ) . "'\n";
			print "DEBUG: calling env...\n";
			system('env');
			system(@tshark_args);
		} else {
			push( @tshark_args, '-Q' );
			my @tshark_args_quoted;
			my $command=shell_quote(@tshark_args);
			my $tshark_output = `$command 2>&1`;
		}
		if ( $self->{debug} ) {
			print "DEBUG: returned... results... ";
			system('pwd');
			system( '/bin/ls', '-l' );
		}
	} ## end foreach my $span ( @{ $self->{spans} } )

	my $results = {
		'oks'       => [],
		'warnings'  => [],
		'criticals' => [],
		'errors'    => [],
		'ignored'   => [],
		status      => 0,
	};

	# process each PCAP into a hash
	my $span_packets = {};
	my $span_int     = 0;
	foreach my $span_name (@span_names) {
		if ( $self->{debug} ) {
			print 'DEBUG: processing ' . $span_name . ".pcap\n";
		}
		if ( -f $span_name . '.pcap' ) {
			my $pcap_json = `tshark -r "$span_name".pcap -T json -J "ip eth tcp udp" 2> /dev/null`;
			if ( $self->{debug} ) {
				print 'DEBUG: dumped ' . $span_name . ".pcap to json\n";
			}
			eval {
				if ( $self->{debug} ) {
					print "DEBUG: processing json\n";
				}
				my $pcap_data = decode_json($pcap_json);
				$span_packets->{$span_name} = $pcap_data;
			};
			if ($@) {
				if ( $self->{debug} ) {
					print 'DEBUG: parsing json failed... ' . $@ . "\n";
				}
				push(
					@{ $self->{warnings} },
					'Failed to parse PCAP for span "' . $self->get_span_name($span_int) . '"... ' . $@
				);
			}
		} else {
			if ( $self->{debug} ) {
				print 'DEBUG: ' . $span_name . ".pcap does not exist\n";
			}
			push( @{ $self->{warnings} }, 'Failed capture PCAP for "' . $self->get_span_name($span_int) . '"' );
		}
		$span_int++;
	} ## end foreach my $span_name (@span_names)

	if ( $self->{debug} ) {
		print "DEBUG: starting processing connection data\n";
	}
	my $connections               = {};
	my $port_connections_per_span = {};
	my $port_connections_per_port = {};
	foreach my $port ( @{ $self->{ports} } ) {
		$port_connections_per_port->{$port} = 0;
	}
	my $packet_count      = {};
	my $span_packet_count = {};
	foreach my $span_name (@span_names) {
		if ( $self->{debug} ) {
			print 'DEBUG: processing connection data for ' . $span_name . "\n";
		}
		$connections->{$span_name}               = {};
		$port_connections_per_span->{$span_name} = 0;
		if ( defined( $span_packets->{$span_name} ) && ref( $span_packets->{$span_name} ) eq 'ARRAY' ) {
			$span_packet_count->{$span_name} = $#{ $span_packets->{$span_name} } + 1;

			# process each packet for
			foreach my $packet ( @{ $span_packets->{$span_name} } ) {
				eval {
					if (   defined( $packet->{_source} )
						&& defined( $packet->{_source}{layers} )
						&& defined( $packet->{_source}{layers}{eth} ) )
					{
						my $name     = '';
						my $proto    = '';
						my $dst_ip   = '';
						my $dst_port = '';
						my $src_ip   = '';
						my $src_port = '';

						# used for skipping odd broken packets or and broad cast stuff
						my $add_it = 1;

						if ( defined( $packet->{_source}{layers}{udp} ) ) {
							$proto = 'udp';
							if ( defined( $packet->{_source}{layers}{udp}{'udp.dstport'} ) ) {
								$dst_port = $packet->{_source}{layers}{udp}{'udp.dstport'};
							} else {
								$add_it = 0;
							}
							if ( defined( $packet->{_source}{layers}{udp}{'udp.srcport'} ) ) {
								$src_port = $packet->{_source}{layers}{udp}{'udp.srcport'};
							} else {
								$add_it = 0;
							}
						} ## end if ( defined( $packet->{_source}{layers}{udp...}))
						if ( defined( $packet->{_source}{layers}{tcp} ) ) {
							$proto = 'tcp';
							if ( defined( $packet->{_source}{layers}{tcp}{'tcp.dstport'} ) ) {
								$dst_port = $packet->{_source}{layers}{tcp}{'tcp.dstport'};
							} else {
								$add_it = 0;
							}
							if ( defined( $packet->{_source}{layers}{tcp}{'tcp.srcport'} ) ) {
								$src_port = $packet->{_source}{layers}{tcp}{'tcp.srcport'};
							} else {
								$add_it = 0;
							}
						} ## end if ( defined( $packet->{_source}{layers}{tcp...}))
						if (   defined( $packet->{_source}{layers}{ip} )
							&& defined( $packet->{_source}{layers}{ip}{'ip.src'} ) )
						{
							$src_ip = $packet->{_source}{layers}{ip}{'ip.src'};
						} else {
							$add_it = 0;
						}
						if (   defined( $packet->{_source}{layers}{ip} )
							&& defined( $packet->{_source}{layers}{ip}{'ip.dst'} ) )
						{
							$dst_ip = $packet->{_source}{layers}{ip}{'ip.dst'};
						} else {
							$add_it = 0;
						}

						# save the packet to per port info
						if ( $add_it && defined( $self->{ports_check}{$dst_port} ) ) {
							$port_connections_per_span->{$span_name}++;
							$port_connections_per_port->{$dst_port}++;
						}
						if ( $add_it && defined( $self->{ports_check}{$src_port} ) ) {
							$port_connections_per_span->{$span_name}++;
							$port_connections_per_port->{$src_port}++;
						}

						if ($add_it) {
							$name = $proto . '-' . $src_ip . '%' . $src_port . '-' . $dst_ip . '%' . $dst_port;
							$connections->{$span_name}{$name} = $packet;
						}
					} ## end if ( defined( $packet->{_source} ) && defined...)
				};
			} ## end foreach my $packet ( @{ $span_packets->{$span_name...}})
		} else {
			$span_packet_count->{$span_name} = 0;
		}
	} ## end foreach my $span_name (@span_names)

	$results->{port_connections_per_span} = $port_connections_per_span;
	$results->{port_connections_per_port} = $port_connections_per_port;
	$results->{packet_count}              = $packet_count;

	if ( $self->{debug} ) {
		print "DEBUG: checking for bidirectional traffic\n";
	}
	# check each span for bi directional traffic traffic
	$span_int = 0;
	foreach my $span_name (@span_names) {
		if ( $self->{debug} ) {
			print 'DEBUG: processing traffic data for ' . $span_name . "\n";
		}
		my $count = 0;
		# process each connection for the interface looking for matches
		foreach my $packet_name ( keys( %{ $connections->{$span_name} } ) ) {
			my $packet = $connections->{$span_name}{$packet_name};
			if (
				(
					   defined( $packet->{_source}{layers}{ip} )
					&& defined( $packet->{_source}{layers}{ip}{'ip.dst'} )
					&& defined( $packet->{_source}{layers}{ip}{'ip.src'} )
				)
				&& (
					(
						   defined( $packet->{_source}{layers}{tcp} )
						&& defined( $packet->{_source}{layers}{tcp}{'tcp.dstport'} )
						&& defined( $packet->{_source}{layers}{tcp}{'tcp.srcport'} )
					)
					|| (   defined( $packet->{_source}{layers}{udp} )
						&& defined( $packet->{_source}{layers}{udp}{'tcp.dstport'} )
						&& defined( $packet->{_source}{layers}{udp}{'tcp.srcport'} ) )
				)
				)
			{
				my $reverse_packet_name = '';
				my $dst_port            = '';
				my $src_port            = '';
				my $proto               = '';
				my $dst_ip              = $packet->{_source}{layers}{ip}{'ip.dst'};
				my $src_ip              = $packet->{_source}{layers}{ip}{'ip.src'};

				if ( defined( $packet->{_source}{layers}{udp} ) ) {
					$proto = 'udp';
					if ( defined( $packet->{_source}{layers}{udp}{'udp.dstport'} ) ) {
						$dst_port = $packet->{_source}{layers}{udp}{'udp.dstport'};
					}
					if ( defined( $packet->{_source}{layers}{udp}{'udp.srcport'} ) ) {
						$src_port = $packet->{_source}{layers}{udp}{'udp.srcport'};
					}
				}
				if ( defined( $packet->{_source}{layers}{tcp} ) ) {
					$proto = 'tcp';
					if ( defined( $packet->{_source}{layers}{tcp}{'tcp.dstport'} ) ) {
						$dst_port = $packet->{_source}{layers}{tcp}{'tcp.dstport'};
					}
					if ( defined( $packet->{_source}{layers}{tcp}{'tcp.srcport'} ) ) {
						$src_port = $packet->{_source}{layers}{tcp}{'tcp.srcport'};
					}
				}

				$reverse_packet_name = $proto . '-' . $dst_ip . '%' . $dst_port . '-' . $src_ip . '%' . $src_port;

				my $found_it = 0;
				if ( defined( $connections->{$span_name}{$reverse_packet_name} ) ) {
					$found_it = 1;
				}

				if ($found_it) {
					$count++;
				}
			} ## end if ( ( defined( $packet->{_source}{layers}...)))
		} ## end foreach my $packet_name ( keys( %{ $connections...}))

		# if count is less than one, then no streams were found
		if ( $count < 1 ) {
			my $level = 'oks';
			if ( $self->{no_streams} == 1 ) {
				$level = 'warnings';
			} elsif ( $self->{no_streams} == 2 ) {
				$level = 'criticals';
			} elsif ( $self->{no_streams} == 3 ) {
				$level = 'errors';
			}

			my $message = 'No TCP/UDP streams found for span ' . $self->get_span_name($span_int);

			if (   $self->{no_streams_to_ignore}{ $self->get_span_name_for_check($span_int) }
				|| $self->{no_streams_to_ignore}{$span_name} )
			{
				push( @{ $results->{ignored} }, 'IGNORED - ' . $level . ' - ' . $message );
			} else {
				push( @{ $results->{$level} }, $message );
			}
		} else {
			push(
				@{ $results->{oks} },
				'bidirectional TCP/UDP streams, ' . $count . ', found for ' . $self->get_span_name($span_int)
			);
		}

		$span_int++;
	} ## end foreach my $span_name (@span_names)

	if ( $self->{debug} ) {
		print "DEBUG: checking for traffic on ports\n";
	}
	# ensure we got traffic on the specified ports
	$span_int = 0;
	foreach my $span_name (@span_names) {
		if ( $self->{debug} ) {
			print 'DEBUG: processing port data for ' . $span_name . "\n";
		}
		my $ports_found = 0;
		if ( $port_connections_per_span->{$span_name} > 0 ) {
			$ports_found = 1;
		}
		if ( !$ports_found ) {
			my $level = 'oks';
			if ( $self->{port_check} == 1 ) {
				$level = 'warnings';
			} elsif ( $self->{port_check} == 2 ) {
				$level = 'criticals';
			} elsif ( $self->{port_check} == 3 ) {
				$level = 'errors';
			}
			my $message
				= 'no packets for ports '
				. join( ',', @{ $self->{ports} } )
				. ' for span '
				. $self->get_span_name($span_int);

			if (   $self->{port_check_to_ignore}{ $self->get_span_name_for_check($span_int) }
				|| $self->{port_check_to_ignore}{$span_name} )
			{
				push( @{ $results->{ignored} }, 'IGNORED - ' . $level . ' - ' . $message );
			} else {
				push( @{ $results->{$level} }, $message );
			}
		} else {
			push(
				@{ $results->{oks} },
				'ports '
					. join( ',', @{ $self->{ports} } )
					. ' have '
					. $port_connections_per_span->{$span_name}
					. ' packets for span '
					. $self->get_span_name($span_int)
			);
		} ## end else [ if ( !$ports_found ) ]
		$span_int++;
	} ## end foreach my $span_name (@span_names)

	# check for interfaces with no packets
	$span_int = 0;
	foreach my $span_name (@span_names) {
		if ( $span_packet_count->{$span_name} == 0 ) {
			my $level = 'oks';
			if ( $self->{no_packets} == 1 ) {
				$level = 'warnings';
			} elsif ( $self->{no_packets} == 2 ) {
				$level = 'criticals';
			} elsif ( $self->{no_packets} == 3 ) {
				$level = 'errors';
			}
			my $message = 'span ' . $self->get_span_name($span_int) . ' has no packets';
			if (   $self->{no_streams_to_ignore}{ $self->get_span_name_for_check($span_int) }
				|| $self->{no_packets_to_ignore}{$span_name} )
			{
				push( @{ $results->{ignored} }, 'IGNORED - ' . $level . ' - ' . $message );
			} else {
				push( @{ $results->{$level} }, $message );
			}

		} ## end if ( $span_packet_count->{$span_name} == 0)
		$span_int++;
	} ## end foreach my $span_name (@span_names)

	#check for low packet count on interfaces
	$span_int = 0;
	foreach my $span_name (@span_names) {
		if ( $span_packet_count->{$span_name} < $self->{packets} ) {
			my $level = 'oks';
			if ( $self->{low_packets} == 1 ) {
				$level = 'warnings';
			} elsif ( $self->{low_packets} == 2 ) {
				$level = 'criticals';
			} elsif ( $self->{low_packets} == 3 ) {
				$level = 'errors';
			}
			my $message
				= 'span '
				. $self->get_span_name($span_int)
				. ' has a packet count of '
				. $span_packet_count->{$span_name}
				. ' which is less than the required '
				. $self->{packets};
			if (   $self->{low_packets_to_ignore}{ $self->get_span_name_for_check($span_int) }
				|| $self->{low_packets_to_ignore}{$span_name} )
			{
				push( @{ $results->{ignored} }, 'IGNORED - ' . $level . ' - ' . $message );
			} else {
				push( @{ $results->{$level} }, $message );
			}
		} else {
			push(
				@{ $results->{oks} },
				'span ' . $self->get_span_name($span_int) . ' has ' . $span_packet_count->{$span_name} . ' packets'
			);
		}
		$span_int++;
	} ## end foreach my $span_name (@span_names)

	# check for missing interfaces
	if (   $#{ $self->{interfaces_missing} } >= 0
		&& $self->{missing_interface} > 0 )
	{
		my $level = 'oks';
		if ( $self->{missing_interface} == 1 ) {
			$level = 'warnings';
		} elsif ( $self->{missing_interface} == 2 ) {
			$level = 'criticals';
		} elsif ( $self->{missing_interface} == 3 ) {
			$level = 'errors';
		}

		# sort the missing interfaces into ignored and not ignored
		my @ignored_interfaces;
		my @missing_interfaces;
		foreach my $interface ( @{ $self->{interfaces_missing} } ) {
			if ( defined( $self->{missing_interface_to_ignore}{$interface} ) ) {
				push( @ignored_interfaces, $interface );
			} else {
				push( @missing_interfaces, $interface );
			}
		}

		# handle ignored missing interfaces
		if ( defined( $ignored_interfaces[0] ) ) {
			my $message = 'missing interfaces... ' . join( ',', @ignored_interfaces );
			push( @{ $results->{ignored} }, 'IGNORED - ' . $level . ' - ' . $message );
		}

		# handle not ignored missing interfaces
		if ( defined( $ignored_interfaces[0] ) ) {
			my $message = 'missing interfaces... ' . join( ',', @missing_interfaces );
			push( @{ $results->{$level} }, $message );
		}
	}else {
		push( @{ $results->{oks} }, 'no missing interfaces' );
	} ## end if ( $#{ $self->{interfaces_missing} } >= ...)

	# sets the final status
	# initially set to 0, OK
	if ( defined( $results->{errors}[0] ) ) {
		$results->{status} = 3;
	} elsif ( defined( $results->{alerts}[0] ) ) {
		$results->{status} = 2;
	} elsif ( defined( $results->{warnings}[0] ) ) {
		$results->{status} = 1;
	}

	return $results;
} ## end sub check

=head2 get_span_name

Returns span name for display purposes.

=cut

sub get_span_name {
	my $self     = $_[0];
	my $span_int = $_[1];

	if ( !defined($span_int) ) {
		return 'undef';
	}

	if ( !defined( $self->{spans}[$span_int] ) ) {
		return 'undef';
	}

	my $name = join( ',', @{ $self->{spans}[$span_int] } );
	if ( defined( $self->{span_names}[$span_int] ) && $self->{span_names}[$span_int] ne '' ) {
		$name = $self->{span_names}[$span_int] . '(' . $name . ')';
	}

	return $name;
} ## end sub get_span_name

=head2 get_span_name_for_check

Returns span name for check purposes.

=cut

sub get_span_name_for_check {
	my $self     = $_[0];
	my $span_int = $_[1];

	if ( !defined($span_int) ) {
		return 'undef';
	}

	if ( !defined( $self->{spans}[$span_int] ) ) {
		return 'undef';
	}

	if ( defined( $self->{span_names}[$span_int] ) && $self->{span_names}[$span_int] ne '' ) {
		return $self->{span_names}[$span_int];
	}

	return join( ',', @{ $self->{spans}[$span_int] } );
} ## end sub get_span_name_for_check

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-check-networkspans at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Check-NetworkSpans>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Check::NetworkSpans


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Check-NetworkSpans>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Check-NetworkSpans>

=item * Search CPAN

L<https://metacpan.org/release/Check-NetworkSpans>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991


=cut

1;    # End of Check::NetworkSpans
