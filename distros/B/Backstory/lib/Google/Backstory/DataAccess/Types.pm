package Google::Backstory::DataAccess::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataAccessIngestionLabel',
    as InstanceOf['Google::Backstory::DataAccess::DataAccessIngestionLabel'];

coerce 'DataAccessIngestionLabel',
    from HashRef, via { 'Google::Backstory::DataAccess::DataAccessIngestionLabel'->new($_) };

declare 'RepeatedDataAccessIngestionLabel',
    as ArrayRef[DataAccessIngestionLabel()];

coerce 'RepeatedDataAccessIngestionLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::DataAccess::DataAccessIngestionLabel'->new($_) } @$_ ] };

declare 'MapStringDataAccessIngestionLabel',
    as HashRef[DataAccessIngestionLabel()];

declare 'DataAccessLabels',
    as InstanceOf['Google::Backstory::DataAccess::DataAccessLabels'];

coerce 'DataAccessLabels',
    from HashRef, via { 'Google::Backstory::DataAccess::DataAccessLabels'->new($_) };

declare 'RepeatedDataAccessLabels',
    as ArrayRef[DataAccessLabels()];

coerce 'RepeatedDataAccessLabels',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::DataAccess::DataAccessLabels'->new($_) } @$_ ] };

declare 'MapStringDataAccessLabels',
    as HashRef[DataAccessLabels()];

1;

__END__

=head1 NAME

Google::Backstory::DataAccess::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
