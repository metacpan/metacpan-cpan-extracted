package Google::Backstory::Id::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Id',
    as InstanceOf['Google::Backstory::Id::Id'];

coerce 'Id',
    from HashRef, via { 'Google::Backstory::Id::Id'->new($_) };

declare 'RepeatedId',
    as ArrayRef[Id()];

coerce 'RepeatedId',
    from ArrayRef[HashRef], via { [ map { 'Google::Backstory::Id::Id'->new($_) } @$_ ] };

declare 'MapStringId',
    as HashRef[Id()];

declare 'Namespace',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Backstory::Id::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
