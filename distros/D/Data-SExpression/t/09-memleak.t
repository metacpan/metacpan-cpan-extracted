#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test that Data::SExpression objects do not contain reference cycles

=cut

use Test::More;

eval "use Test::Memory::Cycle";
if($@) {
    plan skip_all => 'Not checking for cycles because Test::Memory::Cycle uninstalled';
    exit 0;
} else {
    plan tests => 1;
}

use Data::SExpression;

my $ds = Data::SExpression->new;

memory_cycle_ok($ds);
