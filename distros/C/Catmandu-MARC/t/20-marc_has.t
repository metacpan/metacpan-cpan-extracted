#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;

use Catmandu::Importer::MARC;
use Catmandu::Fix;


my $fixes = <<EOF;
if marc_has(245)
  add_field(test.\$append,'has 245')
end

if marc_has_many(245)
  add_field(test.\$append,'has many 245')
end

if marc_has_many(CAT)
  add_field(test.\$append,'has many CAT')
end

if marc_has_many(920a)
  add_field(test.\$append,'has many 920a')
end

unless marc_has_many(100a)
  add_field(test.\$append,'has not more than one 100a')
end
EOF

my $fixer = Catmandu::Fix->new(fixes => [$fixes]);
my $importer = Catmandu::Importer::MARC->new( file => 't/rug01.aleph', type => "ALEPHSEQ" );
my $records = $fixer->fix($importer)->to_array;

my $errors = $records->[0]->{test};

is_deeply $errors , [
        'has 245' ,
        'has many CAT' ,
        'has many 920a' ,
        'has not more than one 100a' ,
];

done_testing;
