package Armadito::Agent::Antivirus::Armadito;

use strict;
use warnings;
use base 'Armadito::Agent::Antivirus';
use Armadito::Agent::HTTP::Client::ArmaditoAV;

sub new {
	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{name}    = "Armadito";
	$self->{version} = $self->getVersion();

	return $self;
}

sub getJobj {
	my ($self) = @_;

	return {
		name    => $self->{name},
		os_info => $self->{os_info},
		version => $self->{version}
	};
}

sub getVersion {
	my ($self) = @_;

	$self->{av_client} = Armadito::Agent::HTTP::Client::ArmaditoAV->new( taskobj => $self );
	my $jobj = $self->{av_client}->getAntivirusVersion();

	return $jobj->{"antivirus-version"};
}
1;

__END__

=head1 NAME

Armadito::Agent::Antivirus - Armadito Agent Antivirus base class.

=head1 DESCRIPTION

This is a base class for all stuff specific to an Antivirus.

=head1 FUNCTIONS

=head2 new ( $self, %params )

Instanciate Armadito module. Set task's default logger.

=head2 getJobj ( $self )

Return unblessed object for json ecnapsulation.

=head2 getVersion ( $self )

Return Antivirus Version by using RESTful API /version.


