package Google::Backstory::Entity::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EntityMetadata',
    as InstanceOf['Google::Backstory::Entity::EntityMetadata'];

coerce 'EntityMetadata',
    from HashRef, via { 'Google::Backstory::Entity::EntityMetadata'->new($_) };

declare 'RepeatedEntityMetadata',
    as ArrayRef[EntityMetadata()];

coerce 'RepeatedEntityMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Entity::EntityMetadata'->new($_) } @$_ ] };

declare 'MapStringEntityMetadata',
    as HashRef[EntityMetadata()];

declare 'EntityType',
    as (Int | Str);

declare 'SourceType',
    as (Int | Str);

declare 'AtiPrioritization',
    as InstanceOf['Google::Backstory::Entity::AtiPrioritization'];

coerce 'AtiPrioritization',
    from HashRef, via { 'Google::Backstory::Entity::AtiPrioritization'->new($_) };

declare 'RepeatedAtiPrioritization',
    as ArrayRef[AtiPrioritization()];

coerce 'RepeatedAtiPrioritization',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Entity::AtiPrioritization'->new($_) } @$_ ] };

declare 'MapStringAtiPrioritization',
    as HashRef[AtiPrioritization()];

declare 'Entity',
    as InstanceOf['Google::Backstory::Entity::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Backstory::Entity::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Entity::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'Relation',
    as InstanceOf['Google::Backstory::Entity::Relation'];

coerce 'Relation',
    from HashRef, via { 'Google::Backstory::Entity::Relation'->new($_) };

declare 'RepeatedRelation',
    as ArrayRef[Relation()];

coerce 'RepeatedRelation',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Entity::Relation'->new($_) } @$_ ] };

declare 'MapStringRelation',
    as HashRef[Relation()];

declare 'Relationship',
    as (Int | Str);

declare 'Directionality',
    as (Int | Str);

declare 'EntityLabel',
    as (Int | Str);

declare 'Metric',
    as InstanceOf['Google::Backstory::Entity::Metric'];

coerce 'Metric',
    from HashRef, via { 'Google::Backstory::Entity::Metric'->new($_) };

declare 'RepeatedMetric',
    as ArrayRef[Metric()];

coerce 'RepeatedMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Entity::Metric'->new($_) } @$_ ] };

declare 'MapStringMetric',
    as HashRef[Metric()];

declare 'AggregateFunction',
    as (Int | Str);

declare 'MetricName',
    as (Int | Str);

declare 'Dimension',
    as (Int | Str);

declare 'Measure',
    as InstanceOf['Google::Backstory::Entity::Metric::Measure'];

coerce 'Measure',
    from HashRef, via { 'Google::Backstory::Entity::Metric::Measure'->new($_) };

declare 'RepeatedMeasure',
    as ArrayRef[Measure()];

coerce 'RepeatedMeasure',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Entity::Metric::Measure'->new($_) } @$_ ] };

declare 'MapStringMeasure',
    as HashRef[Measure()];

1;

__END__

=head1 NAME

Google::Backstory::Entity::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
