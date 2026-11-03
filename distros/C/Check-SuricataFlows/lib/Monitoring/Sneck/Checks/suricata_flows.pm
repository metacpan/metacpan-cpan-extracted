package Monitoring::Sneck::Checks::suricata_flows;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use Check::SuricataFlows ();

=head1 NAME

Monitoring::Sneck::Checks::suricata_flows - checks Suricata is seeing bi directional flows, through Check::SuricataFlows

=head1 VERSION

Version 0.3.0

=cut

our $VERSION = '0.3.0';

=head1 SYNOPSIS

    suricata_flows|perl:suricata_flows
    suricata_flows|perl:suricata_flows -f /var/log/suricata/flows/current/flow.json -a 20 -w 50
    suricata_flows|perl:suricata_flows -s sensor1 -s sensor2 -i 192.0.2.1

=head1 DESCRIPTION

A L<Monitoring::Sneck::Checks> check, for running L<Check::SuricataFlows>
in process from sneck, or through sneck_check. It is only of use if
L<Monitoring::Sneck::Checks> is installed, which this distribution
does not require.

It takes the same options as check_suricataflows and works out the
status the same way, see L<Check::SuricataFlows> for how flows are read
and counted. A flow file that is not there or can not be read is
UNKNOWN.

The status line has the bi and uni directional counts, followed by the
same lines check_suricataflows prints. Perfdata is the bi and uni
directional counts, and the bi directional count of each sensor given
with -s, as bi_$sensor.

=head1 OPTIONS

- -f <flows.json> :: The flow EVE JSON file.
Default :: /var/log/suricata/flows/current/flow.json

- -a <alert count> :: CRITICAL if the bi directional count is this or under.
Default :: 10

- -w <warn count> :: WARNING if the bi directional count is this or under.
Default :: 20

- -t <seconds> :: How far back to read, in seconds.
Default :: 300

- -m <max lines> :: The most lines to read.
Default :: 500

- -s <sensor> :: A sensor name, from .host, to check for. May be given
more than once.

- -i <IP> :: A IP whose flows are ignored, as source or destination.
May be given more than once.

-t is --timeout for every sneck check, so for this one --timeout is the
same as -t. It is used only as how far back to read, as nothing is
waited on over the network.

=cut

sub option_spec {
	return ( 'f=s', 'a=i', 'w=i', 'm=i', 's=s@', 'i=s@' );
}

# match Check::SuricataFlows, so perfdata has them
sub defaults { return { a => 10, w => 20 } }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $sensors = $self->opt('s') // [];

	# new dies on bad options, which is UNKNOWN
	my $results = Check::SuricataFlows->new(
		flow_file      => $self->opt('f'),
		alert_count    => $self->opt('a'),
		warn_count     => $self->opt('w'),
		read_back_time => $self->opt('timeout'),
		max_lines      => $self->opt('m'),
		sensor_names   => $sensors,
		ignore_IPs     => $self->opt('i') // [],
	)->run;

	my @lines = split( /\n/, $results->{status} );
	if ( $results->{status_code} == 3 ) {
		return $self->finish( $self->UNKNOWN, join( ', ', @lines ) );
	}

	# the counts alert at or under, so as ranges, alert under one more
	my ( $warning, $critical ) = ( ( $self->opt('w') + 1 ) . ':', ( $self->opt('a') + 1 ) . ':' );
	$self->perfdata(
		label    => 'bi',
		value    => $results->{bi_directional_count},
		warning  => $warning,
		critical => $critical,
		min      => 0
	);
	$self->perfdata( label => 'uni', value => $results->{uni_directional_count}, min => 0 );
	foreach my $sensor ( @{$sensors} ) {
		$self->perfdata(
			label    => 'bi_' . $sensor,
			value    => $results->{by_sensor}{$sensor}{bi_directional_count} // 0,
			warning  => $warning,
			critical => $critical,
			min      => 0
		);
	}

	return $self->finish(
		$results->{status_code},
		$results->{bi_directional_count}
			. ' bi directional, '
			. $results->{uni_directional_count}
			. ' uni directional flows',
		@lines
	);
} ## end sub check

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
