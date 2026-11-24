package Google::Backstory::Collection::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Collection',
    as InstanceOf['Google::Backstory::Collection::Collection'];

coerce 'Collection',
    from HashRef, via { 'Google::Backstory::Collection::Collection'->new($_) };

declare 'RepeatedCollection',
    as ArrayRef[Collection()];

coerce 'RepeatedCollection',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Collection::Collection'->new($_) } @$_ ] };

declare 'MapStringCollection',
    as HashRef[Collection()];

declare 'CollectionType',
    as (Int | Str);

declare 'DetectionTimingDetails',
    as (Int | Str);

declare 'RunFrequency',
    as (Int | Str);

declare 'EntityGraphEnrichment',
    as InstanceOf['Google::Backstory::Collection::EntityGraphEnrichment'];

coerce 'EntityGraphEnrichment',
    from HashRef, via { 'Google::Backstory::Collection::EntityGraphEnrichment'->new($_) };

declare 'RepeatedEntityGraphEnrichment',
    as ArrayRef[EntityGraphEnrichment()];

coerce 'RepeatedEntityGraphEnrichment',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Collection::EntityGraphEnrichment'->new($_) } @$_ ] };

declare 'MapStringEntityGraphEnrichment',
    as HashRef[EntityGraphEnrichment()];

declare 'EnrichmentType',
    as (Int | Str);

declare 'DataTableRowInfo',
    as InstanceOf['Google::Backstory::Collection::DataTableRowInfo'];

coerce 'DataTableRowInfo',
    from HashRef, via { 'Google::Backstory::Collection::DataTableRowInfo'->new($_) };

declare 'RepeatedDataTableRowInfo',
    as ArrayRef[DataTableRowInfo()];

coerce 'RepeatedDataTableRowInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Collection::DataTableRowInfo'->new($_) } @$_ ] };

declare 'MapStringDataTableRowInfo',
    as HashRef[DataTableRowInfo()];

declare 'LatencyMetrics',
    as InstanceOf['Google::Backstory::Collection::LatencyMetrics'];

coerce 'LatencyMetrics',
    from HashRef, via { 'Google::Backstory::Collection::LatencyMetrics'->new($_) };

declare 'RepeatedLatencyMetrics',
    as ArrayRef[LatencyMetrics()];

coerce 'RepeatedLatencyMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Collection::LatencyMetrics'->new($_) } @$_ ] };

declare 'MapStringLatencyMetrics',
    as HashRef[LatencyMetrics()];

declare 'Reference',
    as InstanceOf['Google::Backstory::Collection::Reference'];

coerce 'Reference',
    from HashRef, via { 'Google::Backstory::Collection::Reference'->new($_) };

declare 'RepeatedReference',
    as ArrayRef[Reference()];

coerce 'RepeatedReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Collection::Reference'->new($_) } @$_ ] };

declare 'MapStringReference',
    as HashRef[Reference()];

declare 'Element',
    as InstanceOf['Google::Backstory::Collection::Element'];

coerce 'Element',
    from HashRef, via { 'Google::Backstory::Collection::Element'->new($_) };

declare 'RepeatedElement',
    as ArrayRef[Element()];

coerce 'RepeatedElement',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Collection::Element'->new($_) } @$_ ] };

declare 'MapStringElement',
    as HashRef[Element()];

declare 'ResponsePlatformInfo',
    as InstanceOf['Google::Backstory::Collection::ResponsePlatformInfo'];

coerce 'ResponsePlatformInfo',
    from HashRef, via { 'Google::Backstory::Collection::ResponsePlatformInfo'->new($_) };

declare 'RepeatedResponsePlatformInfo',
    as ArrayRef[ResponsePlatformInfo()];

coerce 'RepeatedResponsePlatformInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Collection::ResponsePlatformInfo'->new($_) } @$_ ] };

declare 'MapStringResponsePlatformInfo',
    as HashRef[ResponsePlatformInfo()];

declare 'ResponsePlatformType',
    as (Int | Str);

declare 'SoarAlertMetadata',
    as InstanceOf['Google::Backstory::Collection::SoarAlertMetadata'];

coerce 'SoarAlertMetadata',
    from HashRef, via { 'Google::Backstory::Collection::SoarAlertMetadata'->new($_) };

declare 'RepeatedSoarAlertMetadata',
    as ArrayRef[SoarAlertMetadata()];

coerce 'RepeatedSoarAlertMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Collection::SoarAlertMetadata'->new($_) } @$_ ] };

declare 'MapStringSoarAlertMetadata',
    as HashRef[SoarAlertMetadata()];

1;

__END__

=head1 NAME

Google::Backstory::Collection::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
