#!perl

use strict;
use warnings;
use Test::More;
use Catmandu;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::HTML';
    use_ok $pkg;
};

require_ok $pkg;

my $importer = $pkg->new(file => 't/muse.html');

isa_ok $importer, $pkg;

my $rec = $importer->first;

ok $rec;

done_testing;
