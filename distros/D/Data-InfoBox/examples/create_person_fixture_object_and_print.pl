#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Data::InfoBox::Person;
use Unicode::UTF8 qw(encode_utf8);

my $obj = Test::Shared::Fixture::Data::InfoBox::Person->new;

# Print out.
my $num = 0;
foreach my $item (@{$obj->items}) {
        $num++;
        print "Item $num: ".encode_utf8($item->text->text)."\n";
}

# Output:
# Item 1: Michal Josef Špaček
# Item 2: +420777623160