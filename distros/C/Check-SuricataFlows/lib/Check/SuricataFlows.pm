package Check::SuricataFlows;

use 5.006;
use strict;
use warnings;
use File::ReadBackwards ();
use JSON                qw(decode_json);
use Scalar::Util        qw(looks_like_number);
use Time::Piece         qw( localtime );
use Regexp::IPv6        qw($IPv6_re);
use Regexp::IPv4        qw($IPv4_re);
use NetAddr::IP         ();

=head1 NAME

Check::SuricataFlows - Make sure Suricata is seeing data via reading the Suricata flows json

=head1 VERSION

Version 0.3.0

=cut

our $VERSION = '0.3.0';

=head1 SYNOPSIS

This reads the Suricata EVE JSON flow data file.

    .timestamp :: Used for double checking to make sure we don't read farther
        back than we need to.

If the following is found, the entry is checked.

    .dest_ip
    .src_ip
    .flow.pkts_toclient
    .flow.pkts_toserver

Bi-directional is when .flow.pkts_toclient and .flow.pkts_toserver are both greater
than zero.

Uni-directional is when only .flow.pkts_toclient or .flow.pkts_toserver is greater
than zero and the other is zero.

If all entries found are uni-directional then it is safe to assume the monitored span
is misconfigured.

If sensor_names is used, then each of the specified sensors is checked for. It is
checked from .host in the JSON and the variable for setting that in the Suricata config
is .sensor-name .

Example...

    use Check::SuricataFlows;
    use Data::Dumper;

    my $flow_checker;
    eval {
        $flow_checker = Check::SuricataFlows->new(
            max_lines      => $max_lines,
            read_back_time => $read_back_time,
            warn_count     => $warn_count,
            alert_count    => $alert_count,
            flow_file      => $flow_file,
        );
    };
    if ($@) {
        print 'Failed to call Check::SuricataFlows->new... ' . $@ . "\n";
        exit 3;
    }

    my $results;
    eval { $results = $flow_checker->run; };
    if ($@) {
        print 'Failed to call $flow_checker->run... ' . $@ . "\n";
        exit 3;
    }

    print $results->{status};
    exit $results->{status_code};

=head1 METHODS

=head2 new

Initiates the object.

    - max_lines :: Maximum distance to read back. The sizing of this should be large enough to
           ensure you get enought data that has bidirectional flow info. Likely need to increase for
           very noisy networks.
        default :: 500

    - read_back_time :: How far back to read in seconds. Set to 0 to disable.
        default :: 300

    - warn_count :: Warn if it is less then this for bidirectional traffic.
        default :: 20

    - alert_count :: Alert if it is less than this for bidirectional traffic.
        default :: 10

    - flow_file :: The location json file containing the flow data.
          default :: /var/log/suricata/flows/current/flow.json

    - sensor_names :: A array of sensor names to check for. If specified each of these need to be above
              warn/alert count. If empty or undef, only no checking is done for sensor names, just totals.
          default :: []

    - ignore_IPs :: A array of IPs to ignore.
          default :: []

Example...

    my $flow_checker;
    eval {
        $flow_checker = Check::SuricataFlows->new(
            max_lines      => $max_lines,
            read_back_time => $read_back_time,
            warn_count     => $warn_count,
            alert_count    => $alert_count,
            flow_file      => $flow_file,
        );
    };
    if ($@) {
        print 'Failed to call Check::SuricataFlows->new... ' . $@ . "\n";
        exit 3;
    }

=cut

sub new {
	my ( $blank, %opts ) = @_;

	if ( !defined( $opts{max_lines} ) ) {
		$opts{max_lines} = 500;
	} elsif ( ref( $opts{max_lines} ) ne '' ) {
		die( '$opts{max_lines} of ref type "' . ref( $opts{max_lines} ) . '" and not ""' );
	} elsif ( !looks_like_number( $opts{max_lines} ) ) {
		die( '$opts{max_lines}, "' . $opts{max_lines} . '", does not appear to be numeric' );
	} elsif ( $opts{max_lines} < 1 ) {
		die( '$opts{max_lines}, "' . $opts{max_lines} . '", must be 1 or greater' );
	}

	if ( !defined( $opts{read_back_time} ) ) {
		$opts{read_back_time} = 300;
	} elsif ( ref( $opts{read_back_time} ) ne '' ) {
		die( '$opts{read_back_time} of ref type "' . ref( $opts{read_back_time} ) . '" and not ""' );
	} elsif ( !looks_like_number( $opts{read_back_time} ) ) {
		die( '$opts{read_back_time}, "' . $opts{read_back_time} . '", does not appear to be numeric' );
	} elsif ( $opts{read_back_time} < 1 ) {
		die( '$opts{read_back_time}, "' . $opts{read_back_time} . '", must be 1 or greater' );
	}

	if ( !defined( $opts{warn_count} ) ) {
		$opts{warn_count} = 20;
	} elsif ( ref( $opts{warn_count} ) ne '' ) {
		die( '$opts{warn_count} of ref type "' . ref( $opts{warn_count} ) . '" and not ""' );
	} elsif ( !looks_like_number( $opts{warn_count} ) ) {
		die( '$opts{warn_count}, "' . $opts{warn_count} . '", does not appear to be numeric' );
	}

	if ( !defined( $opts{alert_count} ) ) {
		$opts{alert_count} = 10;
	} elsif ( ref( $opts{alert_count} ) ne '' ) {
		die( '$opts{alert_count} of ref type "' . ref( $opts{alert_count} ) . '" and not ""' );
	} elsif ( !looks_like_number( $opts{alert_count} ) ) {
		die( '$opts{alert_count}, "' . $opts{alert_count} . '", does not appear to be numeric' );
	}

	if ( !defined( $opts{flow_file} ) ) {
		$opts{flow_file} = '/var/log/suricata/flows/current/flow.json';
	} elsif ( ref( $opts{flow_file} ) ne '' ) {
		die( '$opts{flow_file} of ref type "' . ref( $opts{flow_file} ) . '" and not ""' );
	}

	if ( !defined( $opts{sensor_names} ) ) {
		$opts{sensor_names} = [];
	} elsif ( ref( $opts{sensor_names} ) ne 'ARRAY' ) {
		die( '$opts{sensor_names} of ref type "' . ref( $opts{sensor_names} ) . '" and not "ARRAY"' );
	} else {
		my $sensor_names_int = 0;
		while ( defined( $opts{sensor_names}[$sensor_names_int] ) ) {
			if ( ref( $opts{sensor_names}[$sensor_names_int] ) ne '' ) {
				die(      '$opts{sensor_names}['
						. $sensor_names_int
						. '] of ref type "'
						. ref( $opts{sensor_names}[$sensor_names_int] )
						. '" and not ""' );
			}
			$sensor_names_int++;
		} ## end while ( defined( $opts{sensor_names}[$sensor_names_int...]))
	} ## end else [ if ( !defined( $opts{sensor_names} ) ) ]

	my @ignore_IPs;
	my $ignore_IPs_lookup = {};
	if ( defined( $opts{ignore_IPs} ) ) {
		if ( ref( $opts{ignore_IPs} ) ne 'ARRAY' ) {
			die( '$opts{ignore_IPs} of ref type "' . ref( $opts{ignore_IPs} ) . '" and not "ARRAY"' );
		}

		my $ignore_IPs_int = 0;
		while ( defined( $opts{ignore_IPs}[$ignore_IPs_int] ) ) {
			if ( ref( $opts{ignore_IPs}[$ignore_IPs_int] ) ne '' ) {
				die(      '$opts{ignore_IPs}['
						. $ignore_IPs_int
						. '] of ref type "'
						. ref( $opts{ignore_IPs}[$ignore_IPs_int] )
						. '" and not ""' );
			}

			if (   ( $opts{ignore_IPs}[$ignore_IPs_int] !~ /^$IPv6_re$/ )
				&& ( $opts{ignore_IPs}[$ignore_IPs_int] !~ /^$IPv4_re$/ ) )
			{
				die(      '$opts{ignore_IPs}['
						. $ignore_IPs_int . '], "'
						. $opts{ignore_IPs}[$ignore_IPs_int]
						. '", does not appear to be IPv4 or IPv6' );
			}
			eval {
				my $ip = NetAddr::IP->new( $opts{ignore_IPs}[$ignore_IPs_int] );
				push( @ignore_IPs, $ip->addr );
			};
			if ($@) {
				die(      '$opts{ignore_IPs}['
						. $ignore_IPs_int . '], "'
						. $opts{ignore_IPs}[$ignore_IPs_int]
						. '", could not be parsed... '
						. $@ );
			}

			$ignore_IPs_int++;
		} ## end while ( defined( $opts{ignore_IPs}[$ignore_IPs_int...]))

		foreach my $ip (@ignore_IPs) {
			$ignore_IPs_lookup->{$ip} = 1;
		}
	} ## end if ( defined( $opts{ignore_IPs} ) )

	my $self = {
		flow_file         => $opts{flow_file},
		alert_count       => $opts{alert_count},
		warn_count        => $opts{warn_count},
		read_back_time    => $opts{read_back_time},
		max_lines         => $opts{max_lines},
		sensor_names      => $opts{sensor_names},
		ignore_IPs        => \@ignore_IPs,
		ignore_IPs_lookup => $ignore_IPs_lookup,
	};
	bless $self;

	return $self;
} ## end sub new

=head2 run

This method runs the check.

Possible fatal errors such as the flow file not existing or being readable
results in a status_code of 3 being set and a description set in status.

This returns a hash ref. The keys are as below.

    - status :: Status string for the results.

    - status_code :: Nagios style int. 0=OK, 1=WARN, 2=ALERT, 3=UNKNOWN/ERROR

    - lines_read :: Number of lines read.

    - lines_parsed :: Number of lines successfully parsed.

    - lines_get_errored :: Number of lines that resulted in fetch errors.

    - lines_get_errors :: A array of strings of errors encountered when getting the next flow entry to process.

    - bi_directional_count :: Count of bi-directional flows.

    - uni_directional_count :: Count of uni-directional flows.

    - ip_ignored_lines :: Lines ignored thanks to src/dest IP.

    - ip_parse_errored :: Lines in which the src/dest IP could not be parsed.

    - ip_parse_errors :: Array containing error info on src/dest IP c parsing issues.

Example...

    my $results;
    eval { $results = $flow_checker->run; };
    if ($@) {
        print 'Failed to call $flow_checker->run... ' . $@ . "\n";
        exit 3;
    }

    print $results->{status};
    exit $results->{status_code};

=cut

sub run {
	my $self = $_[0];

	my $to_return = {
		status                => '',
		status_code           => 0,
		lines_read            => 0,
		lines_parsed          => 0,
		lines_get_errored     => 0,
		bi_directional_count  => 0,
		uni_directional_count => 0,
		lines_get_errors      => [],
		by_sensor             => {},
		ip_ignored_lines      => 0,
		ip_parse_errored      => 0,
		ip_parse_errors       => [],
	};

	# can't go any further if we can't read the file
	if ( !-e $self->{flow_file} ) {
		$to_return->{status}      = "flow file, '" . $self->{flow_file} . "', does not exist\n";
		$to_return->{status_code} = 3;
		return $to_return;
	} elsif ( !-r $self->{flow_file} ) {
		$to_return->{status}      = "flow file, '" . $self->{flow_file} . "', not readable\n";
		$to_return->{status_code} = 3;
		return $to_return;
	}

	# get the current time and figure when we should read back till
	my $read_till = localtime;
	$read_till = $read_till - $self->{read_back_time};

	# init readbackwards and if we can't we can't go any further
	my $bw;
	eval { $bw = File::ReadBackwards->new( $self->{flow_file} )
			or die "can't read '" . $self->{flow_file} . "' $!"; };
	if ($@) {
		$to_return->{status}
			= "Failed to initiate File::ReadBackwards for  '" . $self->{flow_file} . "' ... " . $@ . "\n";
		$to_return->{status_code} = 3;
		return $to_return;
	}

	# as long as this is true, we should continue reading the file
	my $process = 1;
	# for keeping track of number of lines read
	my $line_count;
	while ($process) {
		$line_count++;
		if ( $line_count > $self->{max_lines} ) {
			$process = 0;
		} elsif ( $bw->eof ) {
			$process = 0;
		}

		if ($process) {
			my $parsed_line;
			my $process_line = 0;
			eval {
				my $line = $bw->readline;

				$to_return->{lines_read}++;

				$parsed_line = decode_json($line);

				$to_return->{lines_parsed}++;

				$process_line = 1;
			};
			if ($@) {
				push( @{ $to_return->{lines_get_errors} }, $@ );
				$to_return->{lines_get_errored}++;
			} elsif ($process_line) {
				my $time_good = 0;

				if ( defined( $parsed_line->{'timestamp'} ) ) {
					$parsed_line->{'timestamp'} =~ s/\.[0-9]+//;

					my $time;
					eval { $time = Time::Piece->strptime( $parsed_line->{'timestamp'}, '%Y-%m-%dT%T%z' ); };
					if ( defined($time) && $time >= $read_till ) {
						$time_good = 1;
					} elsif ( defined($time) && $time < $read_till ) {
						$process = 0;
					}
				} ## end if ( defined( $parsed_line->{'timestamp'} ...))

				if (   $time_good
					&& defined( $parsed_line->{'dest_ip'} )
					&& ( ref( $parsed_line->{'dest_ip'} ) eq '' )
					&& defined( $parsed_line->{'src_ip'} )
					&& ( ref( $parsed_line->{'src_ip'} ) eq '' )
					&& defined( $parsed_line->{'flow'} )
					&& ( ref( $parsed_line->{'flow'} ) eq 'HASH' )
					&& defined( $parsed_line->{'flow'}{'pkts_toclient'} )
					&& ( ref( $parsed_line->{'flow'}{'pkts_toclient'} ) eq '' )
					&& looks_like_number( $parsed_line->{'flow'}{'pkts_toclient'} )
					&& defined( $parsed_line->{'flow'}{'pkts_toserver'} )
					&& ( ref( $parsed_line->{'flow'}{'pkts_toserver'} ) eq '' )
					&& looks_like_number( $parsed_line->{'flow'}{'pkts_toserver'} ) )
				{
					my $IP_ignore = 0;

					eval {
						my $src_ip = NetAddr::IP->new( $parsed_line->{'src_ip'} );
						if ( $self->{ignore_IPs_lookup}{ $src_ip->addr } ) {
							$IP_ignore = 1;
						}
						if ( !$IP_ignore ) {
							my $dest_ip = NetAddr::IP->new( $parsed_line->{'dest_ip'} );
							if ( $self->{ignore_IPs_lookup}{ $dest_ip->addr } ) {
								$IP_ignore = 1;
							}
						}
					};
					if ($@) {
						push( @{ $to_return->{ip_parse_errors} }, $@ );
						$to_return->{ip_parse_errored}++;
					}

					if ( !$IP_ignore ) {
						# .host is not there unless sensor-name is set, and undef as a key warns
						my $sensor = $parsed_line->{'host'} // '';
						if ( !defined( $to_return->{by_sensor}{$sensor} ) ) {
							$to_return->{by_sensor}{$sensor} = {
								bi_directional_count  => 0,
								uni_directional_count => 0,
							};
						}
						if (   ( $parsed_line->{'flow'}{'pkts_toserver'} > 0 )
							&& ( $parsed_line->{'flow'}{'pkts_toclient'} > 0 ) )
						{
							$to_return->{bi_directional_count}++;
							$to_return->{by_sensor}{$sensor}{bi_directional_count}++;
						} else {
							$to_return->{uni_directional_count}++;
							$to_return->{by_sensor}{$sensor}{uni_directional_count}++;
						}
					} else {
						$to_return->{ip_ignored_lines}++;
					}
				} ## end if ( $time_good && defined( $parsed_line->...))
			} ## end elsif ($process_line)
		} ## end if ($process)
	} ## end while ($process)

	if ( $to_return->{bi_directional_count} <= $self->{alert_count} ) {
		$to_return->{status}
			= 'ALERT: bi directional count of '
			. $to_return->{bi_directional_count}
			. ' is less than '
			. $self->{alert_count} . "\n";
		$to_return->{status_code} = 2;
	} elsif ( $to_return->{bi_directional_count} <= $self->{warn_count} ) {
		$to_return->{status}
			= 'WARN: bi directional count of '
			. $to_return->{bi_directional_count}
			. ' is less than '
			. $self->{warn_count} . "\n";
		$to_return->{status_code} = 1;
	} else {
		$to_return->{status} = 'OK: bi directional count of ' . $to_return->{bi_directional_count} . "\n";
	}

	if ( defined( $self->{sensor_names}[0] ) ) {
		foreach my $sensor ( @{ $self->{sensor_names} } ) {
			if ( defined( $to_return->{by_sensor}{$sensor} ) ) {
				if ( $to_return->{by_sensor}{$sensor}{bi_directional_count} <= $self->{alert_count} ) {
					$to_return->{status}
						= $to_return->{status}
						. 'ALERT, '
						. $sensor
						. ': bi directional count of '
						. $to_return->{by_sensor}{$sensor}{bi_directional_count}
						. ' is less than '
						. $self->{alert_count} . "\n";
					$to_return->{status_code} = 2;
				} elsif ( $to_return->{by_sensor}{$sensor}{bi_directional_count} <= $self->{warn_count} ) {
					$to_return->{status}
						= $to_return->{status}
						. 'WARN, '
						. $sensor
						. ': bi directional count of '
						. $to_return->{by_sensor}{$sensor}{bi_directional_count}
						. ' is less than '
						. $self->{warn_count} . "\n";
					if ( $to_return->{status_code} < 1 ) {
						$to_return->{status_code} = 1;
					}
				} else {
					$to_return->{status}
						= $to_return->{status} . 'OK, '
						. $sensor
						. ': bi directional count of '
						. $to_return->{by_sensor}{$sensor}{bi_directional_count} . "\n";
				}
			} else {
				$to_return->{status}      = $to_return->{status} . 'ALERT, ' . $sensor . ": sensor never seen\n";
				$to_return->{status_code} = 2;
			}
		} ## end foreach my $sensor ( @{ $self->{sensor_names} })
	} ## end if ( defined( $self->{sensor_names}[0] ) )

	$to_return->{status} = $to_return->{status} . 'uni directional: ' . $to_return->{uni_directional_count} . "\n";
	foreach my $sensor ( @{ $self->{sensor_names} } ) {
		if ( defined( $to_return->{by_sensor}{$sensor} ) ) {
			$to_return->{status}
				= $to_return->{status}
				. 'uni directional, '
				. $sensor . ': '
				. $to_return->{by_sensor}{$sensor}{uni_directional_count} . "\n";
		} else {
			$to_return->{status} = $to_return->{status} . 'uni directional, ' . $sensor . ": 0\n";
		}
	} ## end foreach my $sensor ( @{ $self->{sensor_names} })
	$to_return->{status}
		= $to_return->{status} . 'seen sensors: ' . join( ', ', keys( %{ $to_return->{by_sensor} } ) ) . "\n";
	$to_return->{status}
		= $to_return->{status} . 'ignored IPs: ' . join( ', ', @{ $self->{ignore_IPs} } ) . "\n";
	$to_return->{status} = $to_return->{status} . 'max lines to read: ' . $self->{max_lines} . "\n";
	$to_return->{status} = $to_return->{status} . 'lines read: ' . $to_return->{lines_read} . "\n";
	$to_return->{status} = $to_return->{status} . 'lines parsed: ' . $to_return->{lines_parsed} . "\n";
	$to_return->{status} = $to_return->{status} . 'line gets errored: ' . $to_return->{lines_get_errored} . "\n";
	$to_return->{status} = $to_return->{status} . 'IP parse errored: ' . $to_return->{ip_parse_errored} . "\n";

	return $to_return;
} ## end sub run

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-check-suricataflows at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Check-SuricataFlows>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Check::SuricataFlows


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Check-SuricataFlows>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Check-SuricataFlows>

=item * Search CPAN

L<https://metacpan.org/release/Check-SuricataFlows>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991


=cut

1;    # End of Check::SuricataFlows
