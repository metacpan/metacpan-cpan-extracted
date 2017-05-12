package Cisco::UCS::Common::EnvironmentalStats;

use strict;
use warnings;

use Scalar::Util qw(weaken);

our $VERSION = '0.51';

our %V_MAP = (
	inputCurrent	=> 'input_current',
	inputCurrentAvg	=> 'input_current_avg',
	inputCurrentMin => 'input_current_min',
	inputCurrentMax => 'input_current_max',
	#intervals	=> 'intervals',
	temperature	=> 'temperature',
	temperatureAvg	=> 'temperature_avg',
	temperatureMin	=> 'temperature_min',
	temperatureMax	=> 'temperature_max',
	thresholded	=> 'thresholded',
	suspect		=> 'suspect',
	timeCollected	=> 'time_collected',
	#update		=> 'update'
);

{ no strict 'refs';

	while ( my ($attribute, $pseudo) = each %V_MAP ) {
		*{ __PACKAGE__ .'::'. $pseudo } = sub {
			my $self = shift;
			return $self->{$attribute}
		}
	}
}

sub new {
	my ( $class, $args ) = @_;

	my $self = bless {}, $class;
	
	foreach my $var ( keys %$args ) {
		$self->{ $var } = $args->{ $var };
	}

	return $self
}

1;

__END__

=pod

=head1 NAME

Cisco::UCS::Common::EnvironmentalStats - Class for operations with Cisco UCS 
environmental stati.

=cut

=head1 SYNOPSIS

	# Print all blades in all chassis along with a cacti-style listing of 
	# the blades current, maximum and average CPU temperature values.

	map { 
		print "Chassis: " . $_->id ."\n";

		map { 
			print "\tBlade: ". $_->id;

			map {
				print "\n\t\tCPU: ". $_->id 
				. "\n\t\t\tCurrent:". $_->env_stats->temperature
				. "\n\t\t\tMax:". $_->env_stats->temperature_max 
				. "\n\t\t\tAvg:". $_->env_stats->temperature_avg ."\n" 

			}   
			sort { $a->id <=> $b->id } $_->get_cpus
		}
		sort { $a->id <=> $b->id } $_->get_blades 
	} 
	sort { 
		$a->id <=> $b->id 
	} $ucs->get_chassiss;

	# Prints something like:
	#
	# Chassis: 1
	#	Blade: 1
	#		CPU: 1
	#			Current:32.500000
	#			Max:33.000000
	#			Avg:32.375000
	#
	#		CPU: 2
	#			Current:37.000000
	#			Max:37.000000
	#			Avg:32.500000
	#	Blade: 2
	#		CPU: 1
	#			Current:45.500000
	#			Max:46.000000
	#			Avg:45.666668
	# ...etc.

=head1 DECRIPTION

Cisco::UCS::Common::EnvironmentalStats is a class providing operations with 
Cisco UCS environmental stati.

Note that you are not supposed to call the constructor yourself, rather a 
Cisco::UCS::Common::EnvironmentalStats object is created automatically by 
method calls on a L<Cisco::UCS::Blade> object.

=cut

=head1 METHODS

=head3 input_current

Returns the current input current value for the target object.

=head3 input_current_avg

Returns the current average input current value for the target object.

=head3 input_current_min

Returns the current minimum input current value for the target object.

=head3 input_current_max

Returns the current maximum input current value for the target object.

=head3 temperature

Returns the current temperature value for the target object.

=head3 temperature_avg

Returns the average temperature value for the target object.

=head3 temperature_max

Returns the maximum temperature value for the target object.

=head3 temperature_min

Returns the minimum temperature value for the target object.

=head3 thresholded

Flag to indicate if the environmental status is in a thresholded state.

=head3 suspect

Flag to indicate if the environmental status is in a suspect state.

=head3 time_collected

Returns the timestamp at which time the status information were collected.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-cisco-ucs-common-environmentalstats at rt.cpan.org>, or through the web 
interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS-Common-EnvironmentalStats>.  
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS::Common::EnvironmentalStats

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS-Common-EnvironmentalStats>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS-Common-EnvironmentalStats>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS-Common-EnvironmentalStats>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS-Common-EnvironmentalStats/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
