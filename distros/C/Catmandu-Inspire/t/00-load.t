use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg     = 'Catmandu::Importer::Inspire';
    use_ok $pkg;
}
require_ok $pkg;

dies_ok { $pkg->new( fmt => 'endnote' ) } "die of missing arguments";
dies_ok {$pkg->new(id => '811388', fmt => 'mods')} "invalid format";
lives_ok { $pkg->new( doi => '10.1088/1126-6708/2009/03/112' ) } "I'm alive";
lives_ok { $pkg->new( id  => '811388' ) } "I'm alive";
lives_ok { $pkg->new( query => "hadronization" ) } "I'm alive";

done_testing;
