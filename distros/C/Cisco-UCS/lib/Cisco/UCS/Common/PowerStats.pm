package Cisco::UCS::Common::PowerStats;

use strict;
use warnings;

use Scalar::Util qw(weaken);

our $VERSION = '0.51';

our %V_MAP = (
	consumedPower	=> 'consumed_power',
	consumedPowerAvg=> 'consumed_power_avg',
	consumedPowerMin=> 'consumed_power_min',
	consumedPowerMax=> 'consumed_power_max',
	inputCurrent	=> 'input_current',
	inputCurrentAvg	=> 'input_current_avg',
	inputCurrentMin => 'input_current_min',
	inputCurrentMax => 'input_current_max',
	inputVoltage	=> 'input_voltage',
	inputVoltageAvg	=> 'input_voltage_avg',
	inputVoltageMin	=> 'input_voltage_min',
	inputVoltageMax	=> 'input_voltage_max',
	thresholded	=> 'thresholded',
	suspect		=> 'suspect',
	timeCollected	=> 'time_collected'
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

=head1 NAME

Cisco::UCS::Common::PowerStats - Class for operations with Cisco UCS power 
usage statistics.

=cut

=head1 SYNOPSIS

	# Print all blades in all chassis along with a cacti-style listing of 
	# the blades current, minimum and maximum power consumption values.

	map { 
		print "Chassis: " . $_->id ."\n";

		map { print "\tBlade: ". $_->id ." - Power consumed -"
			  . " Current:". $_->power_stats->consumed_power 
			  . " Max:". $_->power_stats->consumed_power_max 
			  . " Min:". $_->power_stats->consumed_power_min ."\n" 
		} 
		sort { $a->id <=> $b->id } $_->get_blades

	} 
	sort { 
		$a->id <=> $b->id 
	} $ucs->get_chassiss;

	# Prints something like:
	#
	# Chassis: 1
	#	Blade: 1 - Power consumed - Current:115.656647 Max:120.913757 Min:110.399513
	#	Blade: 2 - Power consumed - Current:131.427994 Max:139.313675 Min:126.170883
	#	Blade: 3 - Power consumed - Current:131.427994 Max:157.713593 Min:126.170883
	#	Blade: 4 - Power consumed - Current:0.000000 Max:0.000000 Min:0.000000
	#	Blade: 5 - Power consumed - Current:0.000000 Max:0.000000 Min:0.000000
	#	Blade: 6 - Power consumed - Current:0.000000 Max:0.000000 Min:0.000000
	#	Blade: 7 - Power consumed - Current:0.000000 Max:0.000000 Min:0.000000
	#	Blade: 8 - Power consumed - Current:0.000000 Max:0.000000 Min:0.000000
	# Chassis: 2
	#	Blade: 1 - Power consumed - Current:131.427994 Max:136.685120 Min:128.799438
	#	Blade: 2 - Power consumed - Current:126.170883 Max:131.427994 Min:123.542320
	#	Blade: 3 - Power consumed - Current:134.056564 Max:155.085037 Min:131.427994
	# ...etc.

=head1 DESCRIPTION

Cisco::UCS::Common::PowerStats is a class providing operations with a Cisco 
UCS power usage statistics.

Note that you are not supposed to call the constructor yourself, rather a 
Cisco::UCS::Common::PowerStats object is created automatically by method calls 
on a L<Cisco::UCS::Blade> object.

=head1 METHODS

=head3 consumed_power

Returns the current power consumed value for the blade.

=head3 consumed_power_avg

Returns the current average power consumed value for the blade.

=head3 consumed_power_min

Returns the current minimum power consumed value for the blade.

=head3 consumed_power_max

Returns the current maximum power consumed value for the blade.

=head3 input_current

Returns the current input current value for the blade.

=head3 input_current_avg

Returns the current average input current value for the blade.

=head3 input_current_min

Returns the current minimum input current value for the blade.

=head3 input_current_max

Returns the current maximum input current value for the blade.

=head3 input_voltage

Returns the current input voltage value for the blade.

=head3 input_voltage_avg

Returns the current average input voltage value for the blade.

=head3 input_voltage_min

Returns the current minimum input voltage value for the blade.

=head3 input_voltage_max

Returns the current maximum input voltage value for the blade.

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
C<bug-cisco-ucs-common-powerstats at rt.cpan.org>, or through the web 
interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS-Common-PowerStats>.  
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS::Common::PowerStats

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS-Common-PowerStats>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS-Common-PowerStats>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS-Common-PowerStats>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS-Common-PowerStats/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
