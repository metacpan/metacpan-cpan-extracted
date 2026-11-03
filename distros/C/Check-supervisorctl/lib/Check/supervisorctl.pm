package Check::supervisorctl;

use 5.006;
use strict;
use warnings;
use File::Slurp qw(read_dir);

=head1 NAME

Check::supervisorctl - Check the status of supervisorctl to see if it is okay.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

# the statuses supervisorctl knows of
my @STATUSES = ( 'stopped', 'starting', 'running', 'backoff', 'stopping', 'exited', 'fatal', 'unknown' );

# the values that are not a status mapping, without the _val, that parse_mappings knows of
my @OTHER_VALS = ( 'not_running', 'config_missing', 'config_dir_missing', 'config_dir_nonreadable', 'status_error' );

=head1 SYNOPSIS

    use Check::supervisorctl;

    my $check_supervisorctl = Check::supervisorctl->new();
    my $results = $check_supervisorctl->run;
    print join( "\n", @{ $results->{results} } ) . "\n";
    exit( $results->{exit} );

=head1 SUBROUTINES/METHODS

=head2 new

Initiates the object.

    - status_mapping :: A hash of status mapping values.
        default :: {
                stopped  => 2,
                starting => 0,
                running  => 0,
                backoff  => 2,
                stopping => 2,
                exited   => 2,
                fatal    => 2,
                unknown  => 2,
            }

    - not_running_val :: Value for if it a config is not running.
        default :: 2

    - config_missing_val :: Value for if it a config is missing for a running item.
        default :: 2

    - config_dir_missing_val :: Value for if it the config dir is not present.
        default :: 3

    - config_dir_nonreadable_val :: Value for if it the config dir is not readable.
        default :: 3

    - status_error_val :: Value for if supervisorctl status could not be run or
            returned a line that is not a item and status, such as when it can not
            talk to supervisord.
        default :: 3

    - config_check :: Boolean for if it should check the configs or not.
        default :: 0

    - ignore :: A array of running items to ignore.
        default :: []

    - config_ignore :: A array of configs to ignore.
        default :: []

    - config_dir :: Config dir path.
        default :: /usr/local/etc/supervisor/conf.d
        default Linux :: /etc/supervisor/conf.d

=cut

sub new {
	my ( $blank, %opts ) = @_;

	my $self = {
		status_mapping => {
			stopped  => 2,
			starting => 0,
			running  => 0,
			backoff  => 2,
			stopping => 2,
			exited   => 2,
			fatal    => 2,
			unknown  => 2,
		},
		val_to_string => {
			0 => 'OK',
			1 => 'WARNING',
			2 => 'ALERT',
			3 => 'UNKNOWN'
		},
		not_running_val            => 2,
		config_missing_val         => 2,
		config_dir_missing_val     => 3,
		config_dir_nonreadable_val => 3,
		status_error_val           => 3,
		config_check               => 0,
		ignore                     => {},
		config_ignore              => {},
		config_dir                 => '/usr/local/etc/supervisor/conf.d',
	};
	bless $self;

	if ( $^O eq 'linux' ) {
		$self->{config_dir} = '/etc/supervisor/conf.d';
	}

	# read in ignore settings
	if ( defined( $opts{ignore} ) ) {
		if ( ref( $opts{ignore} ) ne 'ARRAY' ) {
			die( '$opts{ignore} not a ref type of ARRAY but "' . ref( $opts{ignore} ) . '"' );
		}
		foreach my $to_ignore ( @{ $opts{ignore} } ) {
			if ( ref($to_ignore) ne '' ) {
				die( 'array $opts{ignore} contains a item that is not of ref type "" but ' . ref($to_ignore) );
			}
			$self->{ignore}{$to_ignore} = 1;
		}
	} ## end if ( defined( $opts{ignore} ) )

	# read in config ignore settings
	if ( defined( $opts{config_ignore} ) ) {
		if ( ref( $opts{config_ignore} ) ne 'ARRAY' ) {
			die( '$opts{config_ignore} not a ref type of ARRAY but "' . ref( $opts{config_ignore} ) . '"' );
		}
		foreach my $to_ignore ( @{ $opts{config_ignore} } ) {
			if ( ref($to_ignore) ne '' ) {
				die( 'array $opts{config_ignore} contains a item that is not of ref type "" but ' . ref($to_ignore) );
			}
			$self->{config_ignore}{$to_ignore} = 1;
		}
	} ## end if ( defined( $opts{config_ignore} ) )

	# read in other status settings
	foreach my $to_read_in ( map { $_ . '_val' } @OTHER_VALS ) {
		if ( defined( $opts{$to_read_in} ) ) {
			if ( ref( $opts{$to_read_in} ) ne '' ) {
				die( '$opts{' . $to_read_in . '} not a ref type of "" not "' . ref( $opts{$to_read_in} ) . '"' );
			}
			if ( $opts{$to_read_in} !~ /^[0123]$/ ) {
				die( '$opts{' . $to_read_in . '} is not 0, 1, 2, or 3, but "' . $opts{$to_read_in} . '"' );
			}
			$self->{$to_read_in} = $opts{$to_read_in};
		}
	} ## end foreach my $to_read_in ( map { $_ . '_val' } @OTHER_VALS)

	# read in any specified status mappings and
	if ( defined( $opts{status_mapping} ) ) {
		if ( ref( $opts{status_mapping} ) ne 'HASH' ) {
			die( '$opts{status_mapping} not a ref type of HASH but "' . ref( $opts{status_mapping} ) . '"' );
		}
		foreach my $status ( keys( %{ $opts{status_mapping} } ) ) {
			my $lc_status = lc($status);
			if ( ref( $opts{status_mapping}{$status} ) ne '' ) {
				die(      '$opts{status_mapping}{'
						. $status
						. '} is not of ref type "" but "'
						. ref( $opts{status_mapping}{$status} )
						. '"' );
			}
			if ( !defined( $self->{status_mapping}{$lc_status} ) ) {
				die( "'" . $status . "' is not a known status type... expected " . join( ', ', @STATUSES ) );
			}
			if ( $opts{status_mapping}{$status} !~ /^[0123]$/ ) {
				die(      '$opts{status_mapping}{'
						. $status
						. '} is not 0, 1, 2, or 3, but "'
						. $opts{status_mapping}{$status}
						. '"' );
			}
			$self->{status_mapping}{$lc_status} = $opts{status_mapping}{$status};
		} ## end foreach my $status ( keys( %{ $opts{status_mapping...}}))
	} ## end if ( defined( $opts{status_mapping} ) )

	if ( defined( $opts{config_check} ) ) {
		if ( ref( $opts{config_check} ) ne '' ) {
			die( '$opts{config_check} is not of ref type "" but "' . ref( $opts{config_check} ) . '"' );
		}
		$self->{config_check} = $opts{config_check};
	}

	if ( defined( $opts{config_dir} ) ) {
		if ( ref( $opts{config_dir} ) ne '' ) {
			die( '$opts{config_dir} is not of ref type "" but "' . ref( $opts{config_dir} ) . '"' );
		}
		$self->{config_dir} = $opts{config_dir};
	}

	return $self;
} ## end sub new

=head2 parse_mappings

Parses a list of status=value strings, as taken by -s for check_supervisorctl,
into a hash of options for L</new>. Whitespace is removed.

The names may be any of the statuses for status_mapping, or not_running,
config_missing, config_dir_missing, config_dir_nonreadable, or status_error
for the matching *_val options.

Dies if one is not in the form of name=value or the name is not known. The values
are checked by L</new>.

    my %mapping_opts = Check::supervisorctl->parse_mappings( 'stopped=1', 'config_missing=1' );
    my $checker = Check::supervisorctl->new( config_check => 1, %mapping_opts );

=cut

sub parse_mappings {
	my ( $blank, @to_parse ) = @_;

	my %other_vals = map { $_ => 1 } @OTHER_VALS;
	my %statuses   = map { $_ => 1 } @STATUSES;

	my %status_mapping;
	my %to_return;
	foreach my $mapping (@to_parse) {
		my $cleaned = $mapping;
		$cleaned =~ s/\s+//g;
		my ( $name, $value ) = split( /\=/, $cleaned, 2 );
		if ( !defined($name) || !defined($value) || $name eq '' || $value eq '' ) {
			die( 'status mapping "' . $mapping . '" is not in the form of name=value' );
		}
		$name = lc($name);
		if ( $other_vals{$name} ) {
			$to_return{ $name . '_val' } = $value;
		} elsif ( $statuses{$name} ) {
			$status_mapping{$name} = $value;
		} else {
			die(      'status mapping "'
					. $mapping
					. '" is not for a known name... expected '
					. join( ', ', @STATUSES, @OTHER_VALS ) );
		}
	} ## end foreach my $mapping (@to_parse)
	$to_return{status_mapping} = \%status_mapping;

	return %to_return;
} ## end sub parse_mappings

=head2 run

This runs it.

    my $results=$check_supervisorctl->run;

    use Data::Dumper;
    print Dumper($results);
    exit($results->{exit});

It optionally takes the output of 'supervisorctl status', for when it has already
been ran by something else. If not given, 'supervisorctl status' is ran.

    - status_output :: The output of 'supervisorctl status'.

    my $results=$check_supervisorctl->run( status_output => $output );

The returned data is as below.

    - .configs[] :: A array of configs found.

    - .config_not_running[] :: A array of configs present but not running.

    - .config_missing[] :: A array of running items was found, but no matchingly named config was found.

    - .config_check :: If it was told to check the configs or not for matching names.

    - .config_dir :: The config dir to check.

    - .config_ignored[] :: Array of configs ignored.

    - .config_ignore :: Configs asked to be ignored.

    - .exit :: Nagios style exit value.

    - .status.$name :: Status of each item.

    - .total :: Number of items found in the status output, not counting ignored ones.

    - .ignored[] :: A array of ignored items.

    - .ignore :: A array of items asked to be ignored.

    - .config_dir_missing :: If the config dir is missing.

    - .config_dir_readable :: If the config dir is readable.

    - .status_list.$status :: A hash of the various statuses with keys being arrays of items for that status.

    - .status_errors[] :: Lines from 'supervisorctl status' that were not a item and status,
            such as when it can not talk to supervisord.

    - .results[] :: A descriptive a array of the results of the check.

=cut

sub run {
	my ( $self, %opts ) = @_;

	my $to_return = {
		configs             => [],
		config_not_running  => [],
		config_missing      => [],
		config_check        => $self->{config_check},
		config_dir          => $self->{config_dir},
		config_ignored      => [],
		config_ignore       => [ sort( keys( %{ $self->{config_ignore} } ) ) ],
		exit                => 0,
		status              => {},
		total               => 0,
		ignored             => [],
		ignore              => [ sort( keys( %{ $self->{ignore} } ) ) ],
		config_dir_missing  => 0,
		config_dir_readable => 1,
		status_list         => { map { $_ => [] } @STATUSES },
		status_errors       => [],
		results             => []
	};

	my $output = $opts{status_output};
	if ( !defined($output) ) {
		$output = `supervisorctl status 2> /dev/null`;
		# -1 is it could not be ran at all and 127 is the shell not finding it
		if ( $? == -1 || ( $? >> 8 ) == 127 ) {
			$self->_status_error( $to_return, 'could not run "supervisorctl status"' );
			$output = '';
		}
	}

	foreach my $line ( split( /\n/, $output ) ) {
		# blank lines are not a problem
		if ( $line =~ /^\s*$/ ) {
			next;
		}
		my ( $name, $status ) = split( /\s+/, $line );
		if ( defined($status) ) {
			$status = lc($status);
		}
		# anything not a item followed by a known status is a problem, such as
		# "unix:///var/run/supervisor.sock no such file" for when supervisord is down
		if ( !defined($status) || !defined( $self->{status_mapping}{$status} ) ) {
			$self->_status_error( $to_return, 'supervisorctl status returned "' . $line . '"' );
			next;
		}
		if ( $self->{ignore}{$name} ) {
			push( @{ $to_return->{ignored} }, $name );
			push( @{ $to_return->{results} }, 'IGNORED - ' . $name . ', ' . $status );
			next;
		}
		$self->_raise_exit( $to_return, $self->{status_mapping}{$status} );
		$to_return->{status}{$name} = $status;
		$to_return->{total}++;
		push( @{ $to_return->{status_list}{$status} }, $name );
		push(
			@{ $to_return->{results} },
			$self->{val_to_string}{ $self->{status_mapping}{$status} } . ' - ' . $name . ', ' . $status
		);
	} ## end foreach my $line ( split( /\n/, $output ) )

	# check the config dir only if asked to
	if ( $self->{config_check} ) {
		# handling for if it does not exist
		if ( -d $self->{config_dir} ) {
			my @dir_entries;
			eval { @dir_entries = read_dir( $self->{config_dir} ); };
			if ($@) {
				$to_return->{config_dir_readable} = 0;
				$self->_raise_exit( $to_return, $self->{config_dir_nonreadable_val} );
				push(
					@{ $to_return->{results} },
					$self->{val_to_string}{ $self->{config_dir_nonreadable_val} }
						. ' - config dir, "'
						. $self->{config_dir}
						. '", not readable'
				);
			} ## end if ($@)
			# if it was readable, process it
			if ( $to_return->{config_dir_readable} ) {
				# a lookup hash of found configs, including ignored ones
				my %configs;
				my %ignored = map { $_ => 1 } @{ $to_return->{ignored} };
				# process each dir entry
				foreach my $entry ( sort(@dir_entries) ) {
					# only process items ending in .conf and that are a file.
					if ( $entry =~ /\.conf$/ && -f $self->{config_dir} . '/' . $entry ) {
						$entry =~ s/\.conf$//;
						$configs{$entry} = 1;
						if ( $self->{config_ignore}{$entry} ) {
							push( @{ $to_return->{config_ignored} }, $entry );
							push( @{ $to_return->{results} },        'IGNORED - config ' . $entry );
						} elsif ( $ignored{$entry} ) {
							# the item is ignored, so if it is running or not does not matter
							push( @{ $to_return->{configs} }, $entry );
						} else {
							push( @{ $to_return->{configs} }, $entry );
							if ( !defined( $to_return->{status}{$entry} ) ) {
								push( @{ $to_return->{config_not_running} }, $entry );
								push(
									@{ $to_return->{results} },
									$self->{val_to_string}{ $self->{not_running_val} }
										. ' - non-running config "'
										. $entry . '"'
								);
								$self->_raise_exit( $to_return, $self->{not_running_val} );
							} else {
								push( @{ $to_return->{results} }, 'OK - config present for ' . $entry );
							}
						} ## end else [ if ( $self->{config_ignore}{$entry} ) ]
					} ## end if ( $entry =~ /\.conf$/ && -f $self->{config_dir...})
				} ## end foreach my $entry ( sort(@dir_entries) )
				foreach my $running ( sort( keys( %{ $to_return->{status} } ) ) ) {
					# only check if it is missing as we already check if a running item exists for a config previously
					if ( !$configs{$running} ) {
						push( @{ $to_return->{config_missing} }, $running );
						push(
							@{ $to_return->{results} },
							$self->{val_to_string}{ $self->{config_missing_val} } . ' - missing config ' . $running
						);
						$self->_raise_exit( $to_return, $self->{config_missing_val} );
					}
				} ## end foreach my $running ( sort( keys( %{ $to_return...})))
			} ## end if ( $to_return->{config_dir_readable} )
		} else {
			$to_return->{config_dir_missing} = 1;
			$self->_raise_exit( $to_return, $self->{config_dir_missing_val} );
			push(
				@{ $to_return->{results} },
				$self->{val_to_string}{ $self->{config_dir_missing_val} }
					. ' - config dir, "'
					. $self->{config_dir}
					. '", missing'
			);
		} ## end else [ if ( -d $self->{config_dir} ) ]
	} ## end if ( $self->{config_check} )

	return $to_return;
} ## end sub run

# raises the exit value in the passed results hash if the new one is higher
sub _raise_exit {
	my ( $self, $to_return, $value ) = @_;

	if ( $to_return->{exit} < $value ) {
		$to_return->{exit} = $value;
	}

	return;
}

# records a problem with supervisorctl status in the passed results hash
sub _status_error {
	my ( $self, $to_return, $error ) = @_;

	push( @{ $to_return->{status_errors} }, $error );
	push( @{ $to_return->{results} },       $self->{val_to_string}{ $self->{status_error_val} } . ' - ' . $error );
	$self->_raise_exit( $to_return, $self->{status_error_val} );

	return;
}

=pod

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-check-supervisorctl at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Check-supervisorctl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Check::supervisorctl


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Check-supervisorctl>

=item * Github issue tracker (report bugs here)

L<https://github.com/VVelox/Check-supervisorctl/issues>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Check-supervisorctl>

=item * Search CPAN

L<https://metacpan.org/release/Check-supervisorctl>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007


=cut

1;    # End of Check::supervisorctl
