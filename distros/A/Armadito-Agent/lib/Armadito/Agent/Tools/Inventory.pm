package Armadito::Agent::Tools::Inventory;

use strict;
use warnings;
use base 'Exporter';

use UNIVERSAL::require();
use Encode;
use English qw(-no_match_vars);

use Armadito::Agent::Tools::File qw(canRun);
use Armadito::Agent::Tools::Dmidecode qw(getDmidecodeInfos);

our @EXPORT_OK = qw(
	getUUID
);

sub getUUID {
	my (%params) = @_;

	if ( canRun('dmidecode') ) {
		my $infos = getDmidecodeInfos();
		return $infos->{1}->[0]->{'UUID'};
	}

	if ( $OSNAME eq "MSWin32" ) {
		Armadito::Agent::Tools::Win32->use(qw(getWMIObjects));
		my ($computer_system_product) = getWMIObjects(
			class      => 'Win32_ComputerSystemProduct',
			properties => [qw/UUID/]
		);

		if ( $computer_system_product->{UUID} !~ /^[0-]+$/ ) {
			return $computer_system_product->{UUID};
		}
	}

	die "Unable to retrieve UUID.";
}

1;
__END__

=head1 NAME

Armadito::Agent::Tools::Inventory - basic functions to get some inventory information

=head1 DESCRIPTION

This module provides a generic function to retrieve the UUID for this computer.

=head1 FUNCTIONS

=head2 getUUID()

Returns UUID for this computer.
