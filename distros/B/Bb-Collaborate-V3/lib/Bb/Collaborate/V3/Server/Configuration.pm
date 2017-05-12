package Bb::Collaborate::V3::Server::Configuration;
use warnings; use strict;

use Mouse;

extends 'Elive::DAO::Singleton','Bb::Collaborate::V3';

=head1 NAME

Bb::Collaborate::V3::Server::Configuration - Server Configuration entity class

=cut

=head1 DESCRIPTION

This class contains important configuration settings.

=cut

__PACKAGE__->entity_name('ServerConfiguration');

=head1 PROPERTIES

=head2 boundaryTime (Int)

The Owning Administrator's boundary time as set in the ELM session defaults.

=cut

has 'boundaryTime' => (is => 'rw', isa => 'Int');

=head2 maxAvailableTalkers (Int)

Your default server's supported maximum simultaneous talkers.

=cut

has 'maxAvailableTalkers' => (is => 'rw', isa => 'Int');

=head2 maxAvailableCameras (Int)

Your default server's supported maximum simultaneous cameras.

=cut

has 'maxAvailableCameras' => (is => 'rw', isa => 'Int');

=head2 raiseHandOnEnter (Bool)

The Owning Administrator's value for the C<raiseHandOnEnter> flag as set in the ELM session defaults.

=cut

has 'raiseHandOnEnter' => (is => 'rw', isa => 'Bool');

=head2 mayUseTelephony (Bool)

A flag that tells whether telephony may be used.

=cut

has 'mayUseTelephony' => (is => 'rw', isa => 'Bool');

=head2 mayUseSecureSignOn (Bool)

This parameter does not apply to ELM.

=cut

has 'mayUseSecureSignOn' => (is => 'rw', isa => 'Bool');

=head2 mustReserveSeats

A flag value that indicates if the session's Reserved Seats value must be specified when creating a new session.

This parameter does not apply to ELM.

=cut

has 'mustReserveSeats' => (is => 'rw', isa => 'Bool');

=head2 timeZone (Str)

The time zone for the ELM instance.

=cut

has 'timeZone' => (is => 'rw', isa => 'Str');

=head1 METHODS

=cut

=head2 get

    my $server_config = Bb::Collaborate::V3::Server::Configuration->get();
    print "Server time-zone is: ".$server_config->timeZone."\n";

Return the server configuration details.

=cut

1;
