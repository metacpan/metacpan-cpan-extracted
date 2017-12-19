#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::MARC;
use Catmandu::Fix;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Condition::marc_has';
    use_ok $pkg;
}

require_ok $pkg;

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

my $record =<<'EOF';
000000002 FMT   L BK
000000002 LDR   L 00000nam^a2200301^i^4500
000000002 001   L 000000002
000000002 1001  L $$aMusterman
000000002 24510 L $$aCatmandu Test
000000002 650 0 L $$aPerl
000000002 650 0 L $$aMARC$$aMARC2
000000002 650 0 L $$a加德滿都
000000002 920 0 L $$ablue$$ared
000000002 CAT 0 L $$atest
000000002 CAT 0 L $$atest
EOF

my $fixer = Catmandu::Fix->new(fixes => [$fixes]);
my $importer = Catmandu::Importer::MARC->new( file => \$record, type => "ALEPHSEQ" );
my $records = $fixer->fix($importer)->to_array;

my $errors = $records->[0]->{test};

is_deeply $errors , [
        'has 245' ,
        'has many CAT' ,
        'has many 920a' ,
        'has not more than one 100a' ,
] , 'got the expected results';

done_testing;
