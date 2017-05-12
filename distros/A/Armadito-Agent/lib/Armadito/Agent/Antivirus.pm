package Armadito::Agent::Antivirus;

use strict;
use warnings;
use English qw(-no_match_vars);

sub new {
	my ( $class, %params ) = @_;

	my $self = {
		logger  => $params{logger},
		os_info => ""
	};

	bless $self, $class;

	$self->{os_info} = $self->getOperatingSystemInfo();

	return $self;
}

sub getOperatingSystemInfo {
	my ($self) = @_;

	my $os_info = {
		name    => $OSNAME,
		libpath => $OSNAME
	};

	if ( $OSNAME eq "MSWin32" ) {
		$os_info->{libpath} = "Win32";
	}

	return $os_info;
}

1;

__END__

=head1 NAME

Armadito::Agent::Antivirus - Armadito Agent Antivirus base class.

=head1 DESCRIPTION

This is a base class for all stuff specific to an Antivirus.

=head1 FUNCTIONS

=head2 new ( $self, %params )

Instanciate Armadito module.

=head2 getOperatingSystemInfo ( $self )

Get Operating system information.

