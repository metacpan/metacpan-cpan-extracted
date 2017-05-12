package Cisco::UCS::Blade::CPU;

use strict;
use warnings;

use Cisco::UCS::Common::EnvironmentalStats;
use Scalar::Util qw(weaken);

our $VERSION = '0.51';

our %V_MAP = (
	arch			=> 'arch',
	cores			=> 'cores',
	coresEnabled		=> 'cores_enabled',
	dn			=> 'dn',
	id			=> 'id',
	model			=> 'model',
	operability		=> 'operability',
	operQualifierReason	=> 'operational_reason',
	operState		=> 'operational_state',
	perf			=> 'perf',
	power			=> 'power',
	presence		=> 'presence',
	revision		=> 'revision',
	serial			=> 'serial',
	socketDesignation	=> 'socket',
	speed			=> 'speed',
	stepping		=> 'stepping',
	thermal			=> 'thermal',
	threads			=> 'threads',
	vendor			=> 'vendor',
	visibility		=> 'visibility',
	voltage			=> 'voltage',
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
        my ( $class, $ucs, $args ) = @_; 

        my $self = bless {}, $class;
	weaken( $self->{ucs} = $ucs );
            
        foreach my $var ( keys %$args ) {
                $self->{ $var } = $args->{ $var };
        }

        return $self
}

sub env_stats {
	my $self = shift;
	return Cisco::UCS::Common::EnvironmentalStats->new( 
		$self->{ucs}->resolve_dn( 
					dn => "$self->{dn}/env-stats" 
				)->{outConfig}->{processorEnvStats} )
}

1;

__END__

=pod

=head1 NAME

Cisco::UCS::Blade::CPU - Class for operations with a Cisco UCS Blade CPUs.

=cut

=head1 SYNOPSIS

	# Print all blades in all chassis along with a cacti-style listing of 
	# the blades current, minimum and maximum power consumption values.

	map { 
		print "Chassis: " . $_->id ."\n";
		map { print "\tCommon::PowerStats: "
			  . $_->id ." - Power consumed -"
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

=head1 DECRIPTION

Cisco::UCS::Blade::CPU is a class providing operations with a Cisco UCS Blade 
CPU.

Note that you are not supposed to call the constructor yourself, rather a 
Cisco::UCS::Blade::CPU object is created automatically by method calls on a 
L<Cisco::UCS::Blade> object.

=head1 METHODS

=head3 arch

Returns the CPU architecture.

=head3 cores

Returns the number of CPU cores.

=head3 cores_enabled

Returns the number of CPU cores enabled.

=head3 env_stats

Returns the environmental status and statistics of the CPU as a 
L<Cisco::UCS::Common::EnvironmentalStats> object.

=head3 dn

Returns the distinguished name of the CPU in the UCS information management 
heirarchy.

=head3 id

Returns the integer ID of the CPU.

=head3 model

Returns the CPU model.

=head3 operability

Returns the CPU operability state.

=head3 operational_reason

Returns the CPU operational reason.

=head3 operational_state

Returns the CPU operational state.

=head3 perf

Returns the CPU performance state.

=head3 power

Returns the CPU power state.

=head3 presence

Returns the CPU presence state.

=head3 revision

Returns the CPU revision level.

=head3 serial

Returns the CPU serial number.

=head3 socket

Returns the CPU socket.

=head3 speed

Returns the CPU speed.

=head3 stepping

Returns the CPU stepping.

=head3 thermal

Returns the CPU thermal state.

=head3 threads

Returns number of the CPU threads.

=head3 vendor

Returns the CPU vendor string.

=head3 visibility

Returns the CPUs visibility.

=head3 voltage

Returns the CPUs voltage.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-cisco-ucs-blade-cpu at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS-Blade-CPU>.  I will 
be notified, and then you'll automatically be notified of progress on your bug 
as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS::Blade::CPU


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS-Blade-CPU>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS-Blade-CPU>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS-Blade-CPU>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS-Blade-CPU/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
