#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use Data::Dumper;
use Acme::Kiyoshi::Array;

my @ary = ();

push @ary, "ズン";
push @ary, "ズン";
push @ary, "ズン";
push @ary, "ズン";
push @ary, "ドコ";
print @ary;

exit;


while () {
    push @ary, qw/ズン ドコ/[rand 2];
    if ($ary[-1] =~ /^キ/) {
        print @ary and die; 
    }
}
