package Cisco::UCS::Chassis::PSU::Stats;

use warnings;
use strict;

use Carp qw(croak);
use Scalar::Util qw(weaken);

our $VERSION = '0.51';

our %ATTRIBUTES	= (
	ambientTemp	=> 'ambient_temp',
	ambientTempAvg	=> 'ambient_temp_avg',
	ambientTempMax	=> 'ambient_temp_max',
	ambientTempMin	=> 'ambient_temp_min',
	id 		=> 'id',
	input210v	=> 'input_210v',
	input210vAvg	=> 'input_210v_avg',
	input210vMax	=> 'output_210v_max',
	input210vMin	=> 'input_210v_min',
	model 		=> 'model',
	operability 	=> 'operability',
	operational	=> 'operState',
	output12v	=> 'output_12v',
	output12vAvg	=> 'output_12v_avg',
	output12vMin	=> 'output_12v_min',
	output12vMax	=> 'output_12v_max',
	output3v3	=> 'output_3v3',
	output3v3Avg	=> 'output_3v3_avg',
	output3v3Max	=> 'output_3v3_max',
	output3v3Min	=> 'output_3v3_min',
	outputCurrent	=> 'output_current',
	outputCurrentAvg=> 'output_current_avg',
	outputCurrentMax=> 'output_current_max',
	outputCurrentMin=> 'output_currenti_min',
	outputPower	=> 'output_power',
	outputPowerAvg	=> 'output_power_avg',,
	outputPowerMin	=> 'output_power_min',
	outputPowerMax	=> 'output_power_max',
	performance	=> 'performance',
	power 		=> 'power',
	presence 	=> 'presence',
	psuTemp1	=> 'psu_temp_1',
	psuTemp2	=> 'psu_temp_2',
	revision 	=> 'revision',
	serial 		=> 'serial',
	suspect		=> 'suspect',
	thresholded	=> 'thresholded',
	timeCollected	=> 'time_collected',
	thermal 	=> 'thermal',
	vendor 		=> 'vendor',
	voltage		=> 'voltage',
);

{
        no strict 'refs';

        while ( my ($attribute, $pseudo) = each %ATTRIBUTES ) {
                *{ __PACKAGE__ . '::' . $pseudo } = sub 
			{ 
				my $self = shift;
				return $self->{$attribute} 
			}
        }
}


sub new {
        my ( $class, $args ) = @_;

        my $self = bless {}, $class;

	foreach my $var ( keys %$args ) {
        	$self->{ $var } = $args->{ $var }
	}
                
        return $self;
}

1;

__END__

=pod

=head1 NAME

Cisco::UCS::Common::PSU - Class for operations with a Cisco UCS PSU.

=head1 SYNOPSIS

	foreach my $psu (sort $ucs->chassis(1)->get_psus) {
		print 'PSU ' . $psu->id . ' voltage: ' . $psu->voltage . "\n" 
	}

	# PSU 1 voltage: ok
	# PSU 2 voltage: ok
	# PSU 3 voltage: ok
	# PSU 4 voltage: ok

	# Print the output power of all chassis, and the output of 
	# each PSU in each chassis
	map { 
		printf( "Chassis: %d - Output power: %.3f\n", 
			$_->id, 
			$_->stats->output_power 
		);

		map {
			printf( "\tPSU: %d - Ouput power: %s\n",
				$_->id,
				$_->stats->output_power 
			)
		}   
		sort { $a->id <=> $b->id } $_->get_psus
	} 
	sort { 
		$a->id <=> $b->id 
	} $ucs->get_chassiss;

	# Should yeild something similar to:
	#
	# Chassis: 1 - Output power: 660.000
	# 	PSU: 1 - Ouput power: 144.096008
	# 	PSU: 2 - Ouput power: 178.934998
	# 	PSU: 3 - Ouput power: 167.005997
	# 	PSU: 4 - Ouput power: 168.112000
	# Chassis: 2 - Output power: 1188.000
	# 	PSU: 1 - Ouput power: 229.653000
	# 	PSU: 2 - Ouput power: 300.200012
	# 	PSU: 3 - Ouput power: 288.192017
	# 	PSU: 4 - Ouput power: 374.696991
	# ... etc.

=head1 DESCRIPTION

Cisco::UCS::Common::PSU::Stats is a class providing common operations with 
Cisco UCS PSU power and environmental statistics.

Note that you are not supposed to call the constructor yourself, rather a 
Cisco::UCS::Common::PSU::Stats object is created for you automatically by the 
stats() method call in L<Cisco::UCS::Chassis::PSU>.

=head1 METHODS

=head3 ambient_temp
=head3 ambient_temp_avg
=head3 ambient_temp_max
=head3 ambient_temp_min
=head3 id
=head3 input_210v
=head3 input_210v_avg
=head3 output_210v_max
=head3 input_210v_min
=head3 model
=head3 operability
=head3 operState
=head3 output_12v
=head3 output_12v_avg
=head3 output_12v_min
=head3 output_12v_max
=head3 output_3v3
=head3 output_3v3_avg
=head3 output_3v3_max
=head3 output_3v3_min
=head3 output_current
=head3 output_current_avg
=head3 output_current_max
=head3 output_currenti_min
=head3 output_power
=head3 output_power_avg
=head3 output_power_min
=head3 output_power_max
=head3 performance
=head3 power
=head3 presence
=head3 psu_temp_1
=head3 psu_temp_2
=head3 revision
=head3 serial
=head3 suspect
=head3 thresholded
=head3 time_collected
=head3 thermal
=head3 vendor
=head3 voltage

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Some methods may return undefined, empty or not yet implemented values.  This 
is dependent on the software and firmware revision level of UCSM and 
components of the UCS cluster.  This is not a bug but is a limitation of UCSM.

Please report any bugs or feature requests to 
C<bug-cisco-ucs-common-psu-stats at rt.cpan.org>, or through the web interface 
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS-Common-PSU-Stats>.  
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS::Common::PSU::Stats

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS-Common-PSU-Stats>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS-Common-PSU-Stats>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS-Common-PSU-Stats>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS-Common-PSU-Stats/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

