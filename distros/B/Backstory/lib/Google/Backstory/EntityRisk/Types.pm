package Google::Backstory::EntityRisk::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EntityRisk',
    as InstanceOf['Google::Backstory::EntityRisk::EntityRisk'];

coerce 'EntityRisk',
    from HashRef, via { 'Google::Backstory::EntityRisk::EntityRisk'->new($_) };

declare 'RepeatedEntityRisk',
    as ArrayRef[EntityRisk()];

coerce 'RepeatedEntityRisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::EntityRisk::EntityRisk'->new($_) } @$_ ] };

declare 'MapStringEntityRisk',
    as HashRef[EntityRisk()];

declare 'RiskDelta',
    as InstanceOf['Google::Backstory::EntityRisk::RiskDelta'];

coerce 'RiskDelta',
    from HashRef, via { 'Google::Backstory::EntityRisk::RiskDelta'->new($_) };

declare 'RepeatedRiskDelta',
    as ArrayRef[RiskDelta()];

coerce 'RepeatedRiskDelta',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::EntityRisk::RiskDelta'->new($_) } @$_ ] };

declare 'MapStringRiskDelta',
    as HashRef[RiskDelta()];

1;

__END__

=head1 NAME

Google::Backstory::EntityRisk::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
