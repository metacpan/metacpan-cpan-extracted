#!/usr/bin/perl

use strict;
use warnings;

use BSD::Getfsent qw(getfsent);

while (my @entry = getfsent()) {
    print "@entry\n";
}
