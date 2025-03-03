#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Data::InfoBox::Address;
use Unicode::UTF8 qw(encode_utf8);

my $obj = Test::Shared::Fixture::Data::InfoBox::Address->new;

# Print out.
my $num = 0;
foreach my $item (@{$obj->items}) {
        $num++;
        print "Item $num: ".encode_utf8($item->text->text)."\n";
}

# Output:
# Item 1: Prvního pluku 211/5
# Item 2: Karlín
# Item 3: 18600 Praha 8