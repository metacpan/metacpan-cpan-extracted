package Business::Giropay::Types;

=head1 NAME

Business::Giropay::Types - type library using Type::Tiny

=cut

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

BEGIN {
    extends "Types::Standard";
}

1;
