package Monitoring::Sneck::Checks::supervisorctl;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use Check::supervisorctl ();

=head1 NAME

Monitoring::Sneck::Checks::supervisorctl - checks supervisorctl status, and optionally the configs, through Check::supervisorctl

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    supervisor|perl:supervisorctl
    supervisor|perl:supervisorctl -c
    supervisor|perl:supervisorctl -c -f /etc/supervisor/conf.d -i foo -d bar -s stopped=1

=head1 DESCRIPTION

A L<Monitoring::Sneck::Checks> check, for running L<Check::supervisorctl>
in process from sneck, or through sneck_check. It is only of use if
L<Monitoring::Sneck::Checks> is installed, which this distribution
does not require.

It takes the same options as check_supervisorctl and works out the
status the same way, see L<Check::supervisorctl>. 'supervisorctl status'
is ran through run_command, so it is stopped if the check times out.
If it can not be ran, or returns anything that is not a item and its
status, such as when it can not talk to supervisord, that is UNKNOWN
by default, changeable via -s status_error=$value.

The status line has the counts of the items in each status, followed by
the same lines check_supervisorctl prints. Perfdata is the count for
each status, the count of ignored items, and if -c is given, the counts
of configs not running and running items missing a config.

=head1 OPTIONS

- -c :: Check the configs as well.

- -f <config_dir> :: The directory to look for configs under if -c is set.
Default :: /usr/local/etc/supervisor/conf.d
Default Linux :: /etc/supervisor/conf.d

- -d <ignore_config> :: A config to ignore. May be given more than once.

- -i <ignore> :: A item from status to ignore. May be given more than once.

- -s <status=value> :: Maps a status to a exit value. May be given more
than once. See check_supervisorctl for what may be mapped.

- -p <supervisorctl> :: The supervisorctl to run.
Default :: supervisorctl

=cut

sub option_spec {
	return ( 'c', 'f=s', 'd=s@', 'i=s@', 's=s@', 'p=s' );
}

sub defaults { return { p => 'supervisorctl' } }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	# both die on bad options, which is UNKNOWN
	my %mapping_opts = Check::supervisorctl->parse_mappings( @{ $self->opt('s') // [] } );
	my $checker      = Check::supervisorctl->new(
		config_check  => $self->opt('c') ? 1 : 0,
		config_dir    => $self->opt('f'),
		config_ignore => $self->opt('d') // [],
		ignore        => $self->opt('i') // [],
		%mapping_opts,
	);

	# the exit is not of use, as it is non-zero if anything is not running, which the output says anyways
	my ( $exit, $output ) = $self->run_command( $self->opt('p'), 'status' );
	my $results = $checker->run( status_output => $output );

	my @statuses = ( 'running', 'starting', 'backoff', 'stopping', 'stopped', 'exited', 'fatal', 'unknown' );
	my @summary;
	foreach my $status (@statuses) {
		my $count = scalar( @{ $results->{status_list}{$status} } );
		$self->perfdata( label => $status, value => $count, min => 0 );
		if ($count) {
			push( @summary, $count . ' ' . $status );
		}
	}
	$self->perfdata( label => 'ignored', value => scalar( @{ $results->{ignored} } ), min => 0 );
	if ( $results->{config_check} ) {
		my $not_running = scalar( @{ $results->{config_not_running} } );
		my $missing     = scalar( @{ $results->{config_missing} } );
		$self->perfdata( label => 'config_not_running', value => $not_running, min => 0 );
		$self->perfdata( label => 'config_missing',     value => $missing,     min => 0 );
		if ($not_running) {
			push( @summary, $not_running . ' config' . ( $not_running == 1 ? '' : 's' ) . ' not running' );
		}
		if ($missing) {
			push( @summary, $missing . ' missing config' . ( $missing == 1 ? '' : 's' ) );
		}
		if ( $results->{config_dir_missing} ) {
			push( @summary, 'config dir missing' );
		} elsif ( !$results->{config_dir_readable} ) {
			push( @summary, 'config dir not readable' );
		}
	} ## end if ( $results->{config_check} )
	if ( defined( $results->{status_errors}[0] ) ) {
		push( @summary, $results->{status_errors}[0] );
	}
	if ( !defined( $summary[0] ) ) {
		push( @summary, 'no items' );
	}

	return $self->finish( $results->{exit}, join( ', ', @summary ), @{ $results->{results} } );
} ## end sub check

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

1;
