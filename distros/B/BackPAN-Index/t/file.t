#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use TestUtils;
use Test::More;

my $b = new_backpan;

my $file = $b->file("authors/id/L/LB/LBROCARD/Acme-Colour-0.16.tar.gz");
is( $file->path,   "authors/id/L/LB/LBROCARD/Acme-Colour-0.16.tar.gz" );
is( $file->filename, "Acme-Colour-0.16.tar.gz");
is( $file->date,   1014330111 );
is( $file->size,   3031 );
is( $file->url,
    "http://backpan.perl.org/authors/id/L/LB/LBROCARD/Acme-Colour-0.16.tar.gz"
);
is $file->release, "Acme-Colour-0.16";

done_testing;
