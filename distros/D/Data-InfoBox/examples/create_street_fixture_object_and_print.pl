#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Data::InfoBox::Street;
use Unicode::UTF8 qw(encode_utf8);

my $obj = Test::Shared::Fixture::Data::InfoBox::Street->new;

# Print out.
my $num = 0;
foreach my $item (@{$obj->items}) {
        $num++;
        print "Item $num: ".encode_utf8($item->text->text)."\n";
}

# Output:
# Item 1: Nábřeží Rudoarmějců
# Item 2: Příbor
# Item 3: Česká republika