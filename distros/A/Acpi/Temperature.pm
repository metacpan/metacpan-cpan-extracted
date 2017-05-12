package Acpi::Temperature;
use Acpi::Field;
use strict;

our $VERSION = '0.1';

my $rfield;

sub new{
	my($class) = shift;
	my($self) = {};

	bless($self,$class);
	
	$rfield = Acpi::Field->new;
	return $self;
}

sub getTemperature{
	my($self) = shift;
	my($temperature) = undef;

	$temperature = $rfield->getValueField("/proc/acpi/thermal_zone/THRM/temperature","temperature");

	return $temperature;
}

sub getState{
	my($self) = shift;

	if($rfield->getValueField("/proc/acpi/thermal_zone/THRM/state","state") eq "ok"){
		return 0;
	}
	else{
		return -1;
	}
}

sub getCritical{
	my($self) = shift;

	my($critical) = $rfield->getValueField("/proc/acpi/thermal_zone/THRM/trip_points","critical (S5)");

	return $critical;
}

sub getPassive{
	my($self) = shift;

	my($passive) = $rfield->getValueField("/proc/acpi/thermal_zone/THRM/trip_points","passive");

	return $passive;
}

sub getActive{
	my($self) = shift;

	my($active) = $rfield->getValueField("/proc/acpi/thermal_zone/THRM/trip_points","active[0]");

	return $active;
}

sub getCoolingMode{
	my($self) = shift;

	if($rfield>getValueField("/proc/acpi/thermal_zone/THRM/cooling_mode","cooling mode") eq "active"){
		return 0;
	}
	else{
		return -1;
	}
}
1;

__END__

=head1 NAME

Acpi::Temperature - A class to get informations about your battery.

=head1 SYNOPSIS

use Acpi::Temperature;

$temperature = Acpi::Temperature->new;

print "Current Temperature".$temperature->getTemperature."\n";

=head1 DESCRIPTION

Acpi::Temperature is used to have information about the temperature of the machine.It's specific for GNU/Linux.

=head1 METHOD DESCRIPTIONS

This sections contains only the methods in Temperature.pm itself.

=over

=item *

new();

Contructor for the class

=item *

getTemperature();

Return the temperature.

=item *

getState();

Return the state.

=item *

getCritical();

Return the critical temperature.

=item *

getPassive();

Return the passive temperature.

=item *

getActive();

Return the active temperature.

=item *

getCoolingMode();

Return 0 if cooling mode is active or -1.

=over

=back

=head1 AUTHORS

=over

=item *

Developed by Shy <shy@cpan.org>.

=back

=cut
