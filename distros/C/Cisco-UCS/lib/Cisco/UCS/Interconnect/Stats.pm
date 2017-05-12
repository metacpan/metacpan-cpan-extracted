package Cisco::UCS::Interconnect::Stats;

use strict;
use warnings;

use Scalar::Util qw(weaken);
use Carp qw(croak);

our $VERSION = '0.51';

our %ATTRIBUTES = (
	load			=> 'load',
	load_avg		=> 'loadAvg',
	load_min		=> 'loadMin',
	load_max		=> 'loadMax',
	mem_available		=> 'memAvailable',
	mem_available_avg	=> 'memAvailableAvg',
	mem_available_min	=> 'memAvailableMin',
	mem_available_max	=> 'memAvailableMax',
	mem_cached		=> 'memCached',
	mem_cached_avg		=> 'memCachedAvg',
	mem_cached_min		=> 'memCachedMin',
	mem_cached_max		=> 'memCachedMax',
	suspect			=> 'oobIfIp',
);

{ no strict 'refs';

        while ( my ( $attribute, $pseudo ) = each %ATTRIBUTES ) {
                *{ __PACKAGE__ .'::'. $attribute } = sub {
                        my $self = shift;
                        return $self->{$pseudo}
                }
        }
}

sub new {
        my ( $class, $args ) = @_;
        my $self = {};
        bless $self, $class;

        while ( my( $k, $v ) = 
			each %{ $args->{outConfig}->{swSystemStats} } ) { 
		$self->{$k} = $v 
	}

        return $self;
}


1;

__END__

=pod

=head1 NAME

Cisco::UCS::Interconnect::Stats - Utility class for representing Cisco UCS 
Interconnect system statistics.

=head1 SYNOPSIS

	# Display the current, min, max and average load
	my $stats = $ucs->interconnect(A)->stats;

	printf( "%20s%10s%10s%10s\n", 
		'current',
		'average',
		'min',
		'max' 
	);

	printf( "Load: %14s%10s%10s%10s\n",
		$stats->load,
		$stats->load_avg,
		$stats->load_min,
		$stats->load_max
	);

	# Prints something like:
                     current   average       min       max
        Load:       1.250000  1.495000  1.030000  1.800000

=head1 DESCRIPTION

Cisco::UCS::Interconnect::Stats is a utility class for representing Cisco UCS
Fabric Interconnect system statistics such as load and memory usage.

Please note that you should not need to call the constructor directly, rather 
a Cisco::UCS::Interconnect::Stats object will be created for you when invoking
methods in parent classes, such as the B<stats()> method in 
L<Cisco::UCS::Interconnect>.

=head2 METHODS

=head3 load

Returns the current load for the target fabric interconnect.

=head3 load_avg

Returns the current load average for the target fabric interconnect.

=head3 load_min

Returns the minimum load observed for the fabric interconnect during the
observation period.

=head3 load_max

Returns the maximum load observed for the fabric interconnect during the
observation period.

=head3 mem_available

Returns the current amount of memory available (in MB) for the target fabric 
interconnect.

=head3 mem_available_avg

Returns the average amount of memory available (in MB) for the target fabric 
interconnect during the observation period.

=head3 mem_available_min

Returns the minimum amount of memory available (in MB) for the target fabric 
interconnect during the observation period.

=head3 mem_available_max

Returns the maximum amount of memory available (in MB) for the target fabric 
interconnect during the observation period.

=head3 mem_cached

Returns the current amount of memory cached (in MB) for the target fabric 
interconnect.

=head3 mem_cached_avg

Returns the observed average amount of memory cached (in MB) for the target 
fabric interconnect during the observation period.

=head3 mem_cached_min


Returns the observed minimum amount of memory cached (in MB) for the target 
fabric interconnect during the observation period.

=head3 mem_cached_max


Returns the observed maximum amount of memory cached (in MB) for the target 
fabric interconnect during the observation period.

=head3 suspect

Returns a boolean (yes or no) value indicating if the statistics should be 
regarded as suspect.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cisco-ucs at rt.cpan.org>, 
or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS>.  I will be 
notified, and then you'll automatically be notified of progress on your bug as 
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS::Interconnect::Stats

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS-Interconnect-Stats>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS-Interconnect-Stats>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS-Interconnect-Stats/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
