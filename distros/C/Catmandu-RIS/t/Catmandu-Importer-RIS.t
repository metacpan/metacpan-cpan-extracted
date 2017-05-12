#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::RIS';
    use_ok $pkg;
}
require_ok $pkg;

my $data = {
	TY => "BOOK",
	TI => "Mastering Perl",
	AU => ["brian d foy", "Randal L. Schwartz", "Tom Christiansen"],
	PY => "2014",
	PB => "O'Reilly",
	XX => "However, import me", # unknown key, import nevertheless
};

my $ris = <<EOF;
TY  - BOOK\r\n
AU  - brian d foy\r\n
AU  - Randal L. Schwartz
AU  - Tom Christiansen
PB  - O'Reilly\r\n
PY  - 2014\r\n
TI  - Mastering Perl\r\n
XX  - However, import me\r\n
ER  -
EOF

my $importer = $pkg->new(file => \$ris);

isa_ok $importer, $pkg;

is_deeply $data, $importer->first, "import data with repeated fields";

$data = {
	TY => "BOOK",
	TI => "Mastering Perl",
	AU => "brian d foy",
	PY => "2014",
	PB => "O'Reilly",
	XX => "However, import me", # unknown key, import nevertheless
};

my $ris2 = <<EOF;
TY  - BOOK\n
AU  - brian d foy\n
PB  - O'Reilly\n
PY  - 2014\n
TI  - Mastering Perl\n
XX  - However, import me\n
ER  -

TY  - BOOK\n
AU  - brian d foy II\n
PB  - O'Reilly\n
PY  - 2015\n
TI  - Mastering Perl\n
XX  - However, import me\n
ER  -
EOF

my $importer2 = $pkg->new(file => \$ris2);

is $importer2->count, 2, "import many records";

my $ris3 = <<EOF;
TY BOOK\n
AU brian d foy\n
   Larry Wall
PB O'Reilly\n
PY 2014\n
TI Mastering Perl\n
XX However, import me\n
ER
EOF

my $importer3 = $pkg->new(file => \$ris3);

isa_ok $importer3, $pkg;

$data->{AU} = ["brian d foy", "Larry Wall"];
is_deeply $data, $importer3->first, "import data with custom separator and ugly data";

my $ris4 = <<EOF;
TY BOOK\n
AU brian d foy\n
   Larry Wall
PB O'Reilly\n
PY 2014\n
TI Mastering Perl\n
XX However, import me\n
ER
EOF

my $importer4 = $pkg->new(file => \$ris4, human => 1);

isa_ok $importer4, $pkg;

is_deeply $importer4->first->{Author} , ["brian d foy", "Larry Wall"] , "human ok";

my $ris5 = <<EOF;
TY BOOK\n
AU brian d foy\n
   Larry Wall
PB O'Reilly\n
PY 2014\n
TI Mastering Perl\n
XX However, import me\n
ER
EOF

my $importer5 = $pkg->new(file => \$ris5, human => 't/human.txt');

isa_ok $importer5, $pkg;

is_deeply $importer5->first->{Author} , ["brian d foy", "Larry Wall"] , "human from file ok";

done_testing;
