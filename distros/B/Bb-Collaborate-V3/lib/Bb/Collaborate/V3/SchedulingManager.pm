package Bb::Collaborate::V3::SchedulingManager;
use warnings; use strict;

use Mouse;

extends 'Elive::DAO::Singleton','Bb::Collaborate::V3';

use Scalar::Util;

=head1 NAME

Bb::Collaborate::V3::SchedulingManager - Scheduling Manager entity class

=cut

=head1 DESCRIPTION

Gets the scheduling manager (ELM) and version.

=cut

__PACKAGE__->entity_name('SchedulingManager');

=head1 PROPERTIES

=head2 manager (Str)

The name of the Scheduling Server. This will be C<ELM> or <SAS>.

=cut

has 'manager' => (is => 'rw', isa => 'Str');

=head2 version (Str)

The version identification information of ELM. This will include version (e.g., 3.3.0) and revision (e.g., 3368).

=cut

has 'version' => (is => 'rw', isa => 'Str');

=head1 METHODS

=cut

=head2 get

    my $scheduling_manager = Bb::Collaborate::V3::SchedulingManager->get();

Return the scheduling manager details.

=cut

1;
