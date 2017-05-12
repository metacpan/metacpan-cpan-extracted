package Cisco::UCS::Chassis::Stats;

use strict;
use warnings;

use Scalar::Util qw(weaken);

our $VERSION = '0.51';

our %V_MAP = (
	inputPower	=> 'input_power',
	inputPowerAvg	=> 'input_power_avg',
	inputPowerMax	=> 'input_power_max',
	inputPowerMin	=> 'input_power_min',
	outputPower	=> 'output_power',
	outputPowerAvg	=> 'output_power_avg',
	outputPowerMax	=> 'output_power_max',
	outputPowerMin	=> 'output_power_min',
	thresholded	=> 'thresholded',
	suspect		=> 'suspect',
	timeCollected	=> 'time_collected',
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

Cisco::UCS::Chassis::Stats - Class for operations with Cisco UCS chassis power 
statistics.

=cut

=head1 SYNOPSIS

	# Print all blades in all chassis along with the chassis current 
	# output power and each blades current input power both in watts and 
	# as a percentage of the chassis input power level.

	map { 
		my $c_power = $_->stats->output_power;

		printf( "Chassis: %d - Output power: %.3f\n", 
			$_->id, 
			$c_power 
		);

		map {
			printf( "\tBlade: %d - Input power: %.3f (%.2f%%)\n",
				$_->id, 
				$_->power_budget->current_power, 
				( $c_power == 0 
					? '-' 
					: ( $_->power_budget->current_power 
						/ $c_power * 100 ) 
				)
			) 
		}   
		sort { $a->id <=> $b->id } $_->get_blades 
	} 
	sort { 
		$a->id <=> $b->id 
	} $ucs->get_chassiss;

	# E.g.
	#
	# Chassis: 1 - Output power: 704.000
	#	Blade: 1 - Input power: 119.000 (16.90%)
	#	Blade: 2 - Input power: 134.000 (19.03%)
	#	Blade: 3 - Input power: 135.000 (19.18%)
	#	Blade: 4 - Input power: 0.000 (0.00%)
	#	Blade: 5 - Input power: 0.000 (0.00%)
	#	Blade: 6 - Input power: 0.000 (0.00%)
	#	Blade: 7 - Input power: 0.000 (0.00%)
	#	Blade: 8 - Input power: 136.000 (19.32%)
	# Chassis: 2 - Output power: 1188.000
	#	Blade: 1 - Input power: 127.000 (10.69%)
	#	Blade: 2 - Input power: 0.000 (0.00%)
	#	Blade: 3 - Input power: 120.000 (10.10%)
	#	Blade: 4 - Input power: 0.000 (0.00%)
	#	Blade: 5 - Input power: 127.000 (10.69%)
	#	Blade: 6 - Input power: 121.000 (10.19%)
	#	Blade: 7 - Input power: 172.000 (14.48%)
	#	Blade: 8 - Input power: 136.000 (11.45%)
	# etc.


=head1 DECRIPTION

Cisco::UCS::Chassis::Stats is a class providing operations with a Cisco UCS 
chassis power statistics.

Note that you are not supposed to call the constructor yourself, rather a 
Cisco::UCS::Chassis::Stats object is created automatically by method calls on 
a L<Cisco::UCS::Chassis> object.

=cut

=head1 METHODS

=head3 input_power

Returns the current input power for the chassis.

=head3 input_power_avg

Returns the average input power value for the chassis.

=head3 input_power_min

Returns the minimum power input value for the chassis.

=head3 input_power_max

Returns the maximum power input value for the chassis.

=head3 output_power

Returns the current output power value for the chassis.

=head3 output_power_avg

Returns the average output power value for the chassis.

=head3 output_power_min

Returns the minimum output power value for the chassis.

=head3 output_power_max

Returns the maximum output power value for the blade.

=head3 thresholded

Returns the input power thresholded state for the blade.

=head3 suspect

Returns the input power suspect state for the blade.

=head3 time_collected

Returns the timestamp at which time the power statsitics were collected.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-cisco-ucs-chassis-stats at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS-Chassis-Stats>.  I 
will be notified, and then you'll automatically be notified of progress on your 
bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS::Chassis::Stats


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS-Chassis-Stats>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS-Chassis-Stats>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS-Chassis-Stats>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS-Chassis-Stats/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
