#!/usr/bin/env perl

use strict;
use warnings;

use Term::ANSIColor;
use Test::Shared::Fixture::Data::InfoBox::Items;
use Unicode::UTF8 qw(encode_utf8);

my $obj = Test::Shared::Fixture::Data::InfoBox::Items->new;

# Print out.
my $num = 0;
foreach my $item (@{$obj->items}) {
        $num++;
        my $icon_char = defined $item->icon
	? color($item->icon->color).encode_utf8($item->icon->char).color('reset')
	: ' ';
        print $icon_char.' '.encode_utf8($item->text->text)."\n";
}

# Output (real output is colored):
# ✓ Create project
#   Present project
# ✗ Add money to project
#   Finish project