package Armadito::Agent::Tools::Security;

use strict;
use warnings;
use base 'Exporter';
use UNIVERSAL::require();

our @EXPORT_OK = qw(
	isANumber
);

sub isANumber {
	my ($unsafe) = @_;

	if ( $unsafe !~ /^\d+$/msi ) {
		return 0;
	}
	return 1;
}
1;

__END__

=head1 NAME

Armadito::Agent::Tools::Security - Armadito Agent security static subroutines.

=head1 DESCRIPTION

This module provides validation functions to improve secuity checks in Armadito Agent. It aims to validate tainted variables. See perlsec for further information.

=head1 FUNCTIONS

=head2 isANumber()

Returns true if the input is a number. It means only digits and at least one.
