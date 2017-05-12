#!/usr/bin/perl

use Test::More;

use strict;
use warnings;
no  warnings 'syntax';

my $garbage = "Debian_CPANTS.txt";

eval {
    require Test::Kwalitee;
    Test::Kwalitee -> import;
};

plan skip_all => "Test::Kwalitee not installed; skipping" if $@;

if (-f $garbage) {
    unlink $garbage or die "Failed to clean up $garbage";
}


__END__
