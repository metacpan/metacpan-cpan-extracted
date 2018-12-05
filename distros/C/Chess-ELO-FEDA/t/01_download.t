use strict;
use warnings;
use Test::More tests=>7;
use Test::Exception;


use_ok 'Chess::ELO::FEDA';

dies_ok sub {Chess::ELO::FEDA->new;}, "Constructor without params";
dies_ok sub {Chess::ELO::FEDA->new(-target=>'test.xls');}, "No target supported: xls";
lives_ok sub {Chess::ELO::FEDA->new(-folder=>'.', -target=>'test.sqlite');}, "Constructor for SQLite";
lives_ok sub {Chess::ELO::FEDA->new(-folder=>'.', -target=>'test.csv');}, "Constructor for CSV";
lives_ok sub {Chess::ELO::FEDA->new(-folder=>'.', -target=>undef);}, "undef backend";

dies_ok sub {Chess::ELO::FEDA->new(-folder=>'/a/path/invalid/' . time(), -target=>'test.sqlite');}, "Invalid path not allowed";

