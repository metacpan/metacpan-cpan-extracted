#!/usr/bin/env perl

use strict;
use warnings;

use Test::Shared::Fixture::Data::InfoBox::Company;
use Unicode::UTF8 qw(encode_utf8);

my $obj = Test::Shared::Fixture::Data::InfoBox::Company->new;

# Print out.
my $num = 0;
foreach my $item (@{$obj->items}) {
        $num++;
        print "Item $num: ".encode_utf8($item->text->text)."\n";
}

# Output:
# Item 1: Volvox Globator
# Item 2: Prvního pluku 211/5
# Item 3: Karlín
# Item 4: 18600 Praha 8
# Item 5: volvox@volvox.cz
# Item 6: +420739639506