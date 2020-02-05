package Cluster::SSH::Helper;

use 5.006;
use strict;
use warnings;
use Config::Tiny;
use String::ShellQuote;
use File::BaseDir qw/xdg_config_home/;

=head1 NAME

Cluster::SSH::Helper - Poll machines in a cluster via SNMP and determine which to run a command on.

=head1 VERSION

Version 0.1.1

=cut

our $VERSION = '0.1.1';

=head1 SYNOPSIS

    use Cluster::SSH::Helper;

    my $csh;
    eval({
        # config using...
        # ~/.config/cluster-ssh-helper/hosts.ini
        # ~/.config/cluster-ssh-helper/config.ini
        $csh= Cluster::SSH::Helper->new_from_ini();
    });
    if ( $@ ){
        die( 'Cluster::SSH::Helper->new_from_ini failed... '.$@ );
    }

    # Run the command on the machine with the lowest 1m load.
    $csh->run({ command=>'uname -a' });

=head1 METHODS

=head2 new

Any initially obvious errors in the passed config or hosts config will result in this method dieing.

Tho hash references are required . The first is the general config and the second is the hosts config.

    my $csh;
    eval({
        $csh= Cluster::SSH::Helper->new( \%config, %hosts );
    });
    if ( $@ ){
        die( 'Cluster::SSH::Helper->new failed... '.$@ );
    }

=cut

sub new {
    my $config = $_[1];
    my $hosts  = $_[2];

    # make sure we have a config and that it is a hash
    if ( defined($config) ) {
        if (   ( ref($config) ne 'HASH' )
            && ( ref($config) ne 'Config::Tiny' ) )
        {
            die( 'The passed reference for the config is not a hash... ' . ref($config) );
        }

        if ( !defined( $config->{'_'} ) ) {
            $config->{'_'} = {};
        }

        if ( defined( $config->{'_'}{'env'} ) ) {
            if ( !defined( $config->{ $config->{'_'}{'env'} } ) ) {
                die( '"' . $config->{'_'}{'env'} . '" is specified as for $config->{_}{env} but it is undefined' );
            }
        }
    }
    else {
        # ALL DEFAULTS!
        $config = { '_' => {} };
    }

    # make sure we have a hosts and that it is a hash
    if ( defined($hosts) ) {
        if ( ( ref($hosts) ne 'HASH' ) && ( ref($config) ne 'Config::Tiny' ) ) {
            die('The passed reference for the hosts is not a hash');
        }
    }
    else {
        # this module is useless with out it
        die('No hash reference passed for the hosts config');
    }

    my $self = {
        config  => $config,
        hosts   => $hosts,
    };
    bless $self;

    # set defaults
    if ( !defined( $self->{config}{_}{warn_on_poll} ) ) {
        $self->{config}{_}{warn_on_poll} = 1;
    }
    if ( !defined( $self->{config}{_}{method} ) ) {
        $self->{config}{_}{method} = 'load_1m';
    }
    if ( !defined( $self->{config}{_}{ssh} ) ) {
        $self->{config}{_}{ssh} = 'ssh';
    }
    if ( !defined( $self->{config}{_}{snmp} ) ) {
        $self->{config}{_}{snmp} = '-v 2c -c public';
    }

    return $self;
}

=head1 new_from_ini

Initiates the this object from a file contiaining the general config and host confg
from two INI files.

There are two optional arguments. The first one is the path to the config INI and the
second is the path to the hosts INI.

If not specifiedied, xdg_config_home.'/cluster-ssh-helper/config.ini'
and xdg_config_home.'/cluster-ssh-helper/hosts.ini' are used.

    my $csh;
    eval({
        $csh= Cluster::SSH::Helper->new_from_ini( $config_path, $hosts_path );
    });
    if ( $@ ){
        die( 'Cluster::SSH::Helper->new_from_ini failed... '.$@ );
    }

=cut

sub new_from_ini {
    my $config_file = $_[1];
    my $hosts_file  = $_[2];

    if ( !defined($config_file) ) {
        $config_file = xdg_config_home . '/cluster-ssh-helper/config.ini';
    }
    if ( !defined($hosts_file) ) {
        $hosts_file = xdg_config_home . '/cluster-ssh-helper/hosts.ini';
    }

    my $config = Config::Tiny->read($config_file);
    if ( !defined($config) ) {
        die( "Failed to read '" . $config_file . "'" );
    }

    my $hosts = Config::Tiny->read($hosts_file);
    if ( !defined($hosts) ) {
        die( 'Failed to read"' . $hosts_file . '"' );
    }

    my $self = Cluster::SSH::Helper->new( $config, $hosts );

    return $self;
}

=head2 run

=head3 command

This is a array to use for building the command that will be run.
Basically thinking of it as @ARGV where $ARGV[0] will be the command
and the rest will the the various flags etc.

=head3 env

This is a alternative env value to use if not using the defaults.

=head3 method

This is the selector method to use if not using the default.

=head3 debug

If set to true, returns the command in question after figuring out what it is.

=head3 print_cmd

Prints the command before running it.

    eval({
        $csh->run({
                   command=>'uname -a',
                   });
    });

=cut

sub run {
    my $self = $_[ 0 ];
    my $opts = $_[ 1 ];

    # make sure we have the options
    if ( !defined( $opts ) ) {
        die( 'No options hash passed' );
    }
    else {
        if ( ref( $opts ) ne 'HASH' ) {
            die( 'The passed item was not a hash reference' );
        }

        if ( !defined( $opts->{ command } ) ) {
            die( '$opts->{command} is not defined' );
        }
    }

	# Gets the method to use
	if (!defined( $opts->{method} )) {
		$opts->{method}=$self->{config}{_}{method};
	}

	# gets the env to use
	my $default_env;
	if ( !defined( $opts->{env} ) ) {
		if ( defined( $self->{config}{_}{env} ) ) {
			$opts->{env} = $self->{config}{_}{env};
		}
		$default_env=1;
	}

	# _ is the root of the ini file... not a section, which are meant to be used as env
	if ( ( defined( $opts->{env} ) && ( $opts->{env} eq '_' ) ) ) {
		die('"_" is not a valid name for a enviroment section');
	}

	# figure out what host to use
	my $host;
	if ( $opts->{method} eq 'load_1m' ) {
		$host = $self->lowest_load_1n;
	} elsif ( $opts->{method} eq 'ram_used_percent' ) {
		$host = $self->lowest_used_ram_percent;
	} else {
		die( '"' . $opts->{method} . '" is not a valid method' );
	}

	# if we don't have a host, no point in proceeding
	if (!defined($host)) {
		die('Unable to get a host. Host chooser method returned undef.');
	}

	# real in host specific stuff
	my $ssh_host = $host;
	if ( defined( $self->{hosts}{$host}{host} ) ) {
		$ssh_host = $self->{hosts}{$host}{host};
	}
	if ( defined( $self->{hosts}{$host}{env} ) && $default_env ) {
		$opts->{env} = $self->{hosts}{$host}{env};
	}

	# makes sure the section exists if one was specified
	if ( defined( $opts->{env} )
		 && !defined( $self->{config}{ $opts->{env} } ) ) {
		die(    '"'
				. $opts->{env}
				. '" is not a defined section in the config' );
	}

	# build the env section if needed.
	my $env_command;
	if ( defined( $opts->{env} ) ) {
		# builds the env commant
		$env_command = '/usr/bin/env';
		foreach my $key ( keys( %{ $self->{config}{'test'} } ) ) {
			$env_command
			= $env_command . ' '
			. shell_quote( shell_quote($key) ) . '='
			. shell_quote( shell_quote( $self->{config}{ $opts->{env} }{$key} ) );
		}
	}

	# the initial command to use
	my $command = $self->{config}{_}{ssh};
	if ( defined( $self->{config}{_}{ssh_user} ) ) {
		$command = $command . ' ' . shell_quote( $self->{config}{_}{ssh_user} ) . '@' . shell_quote($ssh_host);
	}
	else {
		$command = $command . ' ' . $host;
	}

	# add the env command if needed
	if (defined($env_command)) {
		$command=$command.' '.$env_command;
	}

	# add on each argument
	foreach my $part ( @{ $opts->{command} } ) {
		if ( defined($env_command) ) {
			$command = $command . ' '
			. shell_quote( shell_quote( shell_quote($part) ) );
		} else {
			$command = $command . ' ' . shell_quote( shell_quote($part) );
		}
	}

	if ( $opts->{debug} ) {
		return $command;
	}

	if (
		defined($opts->{print_cmd}) &&
		$opts->{print_cmd}
		) {
		print $command."\n";
	}

	system($command);

	return $?;
}

=head2 lowest_load_1n

This returns the host with the lowest 1 minute load.

    my $host = $csh->lowest_load_1m;

=cut

sub lowest_load_1n {
    my $self = $_[ 0 ];

    my @hosts = keys( %{ $self->{ hosts } } );

	# holds a list of the 1 minute laod values for each host
	my %host_loads;
	use Data::Dumper;
    foreach my $host (@hosts) {
        my $snmp;
        my $load;
		# see if we can create it and fetch the OID
        eval {
            $snmp = $self->snmp_command($host).' 1.3.6.1.4.1.2021.10.1.6.1';
			$load=`$snmp`;
			chomp($load);
			$load=~s/.*\:\ //;
        };

        my $poll_failed;
        if ( $@ && $self->{config}{_}{warn_on_poll} ) {
            warn( 'Polling for "' . $host . '" failed with... ' . $@ );
            $poll_failed = 1;
        }

        if ( defined($load) ) {
			# if we are here, then polling worked with out issue
            $host_loads{$host} = $load;
        } elsif ( defined($poll_failed)
				  && !defined($load) ) {
			# If here, it means the polling did not die, but it also did not work
            warn( 'Polling for "' . $host . '" returned undef' );
        }
    }

    my @sorted = sort { $host_loads{$a} <=> $host_loads{$b} } keys(%host_loads);

	# we did not manage to poll anything... or thre are zero hosts
	if (!defined($sorted[0])) {
		die('There are either zero defined hosts or polling failed for all hosts');
	}

	return $sorted[0];
}

=head2 lowest_used_ram_percent

This returns the host with the lowest percent of used RAM.

    my $host = $csh->lowest_used_ram_percent;

=cut

sub lowest_used_ram_percent {
    my $self = $_[ 0 ];

    my @hosts = keys( %{ $self->{ hosts } } );

	# holds a list of the 1 minute laod values for each host
	my %hosts_polled;

    foreach my $host (@hosts) {
		my $snmp;
        my $used;
		my $total;
		my $used_value;
		my $total_value;
		my $percent;
        # see if we can create it and fetch the OID
        eval {
			$snmp = $self->snmp_command($host).' 1.3.6.1.4.1.2021.10.1.6.1';
            $used  = $snmp.' 1.3.6.1.4.1.2021.4.6.0';
            $total = $snmp.' 1.3.6.1.4.1.2021.4.5.0';

			$used_value=`$used`;
			$total_value=`$total_value`;

			$used_value=~s/.*\:\ //;
			$total_value=~s/.*\:\ //;

            $percent = $used_value / $total_value;
        };

        my $poll_failed;
        if ( $@ && $self->{config}{_}{warn_on_poll} ) {
            warn( 'Polling for "' . $host . '" failed with... ' . $@ );
            $poll_failed = 1;
        }

        if ( defined($total) ) {
			# if we are here, then polling worked with out issue
            $hosts_polled{$host} = $percent;
        } elsif ( defined($poll_failed)
				  && !defined($percent) ) {
			# If here, it means the polling did not die, but it also did not work
            warn( 'Polling for "' . $host . '" returned undef' );
        }
    }

    my @sorted = sort { $hosts_polled{$a} <=> $hosts_polled{$b} } keys(%hosts_polled);

	# we did not manage to poll anything... or thre are zero hosts
	if (!defined($sorted[0])) {
		die('There are either zero defined hosts or polling failed for all hosts');
	}

	return $sorted[0];
}

=head2 snmp_command

Generates the full gammand to be used with snmpget minus that OID to fetch.

One argument is taken and that is the host to generate it for.

As long as the host exists, this command will work.

    my $cmd;
    eval({
          $cmd=$cshelper->snmp_command($host);
    });

=cut

sub snmp_command{
	my $self = $_[0];
	my $host = $_[1];

	if (!defined($host)) {
		die('No host defined');
	}

	if (!defined($self->{hosts}{$host})) {
		die('The host "'.$host.'" is not configured');
	}

	my $snmp='';

	if (defined($self->{config}{_}{snmp})) {
		$snmp=$self->{config}{_}{snmp};
	}

	if (defined($self->{hosts}{snmp})) {
		$snmp=$self->{hosts}{snmp};
	}

	return 'snmpget -O vU '.$snmp.' '.$host;
}

=head1 CONFIGURATOIN

=head2 GENERAL

The general configuration.

This is written to be easily loadable via L<Config::Tiny>, hence why '_' is used.

=head3 _

This contains the default settings to use. Each of these may be over ridden on a per host basis.

If use SNMPv3, please see L<Net::SNMP> for more information on the various session options.

=head4 method

This is default method to use for selecting the what host to run the command on. If not specified,
'load' is used.

    load_1m , checks 1 minute load and uses the lowest
    ram_used_percent , uses the host with the lowest used percent of RAM

=head4 ssh

The default command to use for SSH.

If not specified, just 'ssh' will be used.

This should not include either user or host.

=head4 ssh_user

If specified, this will be the default user to use for SSH.

If not specified, SSH is invoked with out specifying a user.

=head4 snmp

This is the default options to use with netsnmp. This should be like
'-v 2c -c public' or the like.

If not specified, this defaults to '-v 2c -c public'.

=head4 env

If specified, '/usr/bin/env' will be inserted before the command to be ran.

The name=values pairs for this will be built using the hash key specified by this.

=head4 warn_on_poll

Issue a warn() on SNMP timeouts or other polling issues. This won't be a automatic failure. Simply timing out
on SNMP means that host will be skipped and not considered.

This defaults to 1, true.

=head2 HOSTS

This contains the hosts to connect to.

Each key of this hash reference is name of the host in question. The value is a hash
containing any desired over rides to the general config.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cluster-ssh-helper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cluster-SSH-Helper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cluster::SSH::Helper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Cluster-SSH-Helper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cluster-SSH-Helper>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Cluster-SSH-Helper>

=item * Search CPAN

L<https://metacpan.org/release/Cluster-SSH-Helper>

=item * Repository

L<https://github.com/VVelox/Cluster-SSH-Helper>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Cluster::SSH::Helper
