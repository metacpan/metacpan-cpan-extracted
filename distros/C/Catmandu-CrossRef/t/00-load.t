use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::CrossRef';
    use_ok $pkg;
}

require_ok $pkg;

dies_ok { $pkg->new( fmt => "unixref" ) } "die of missing arguments";
dies_ok {
    $pkg->new( fmt => "unixref", doi => "10.1088/1126-6708/2009/03/112" );
}
"die of missing arguments";
dies_ok { $pkg->new( usr => 'me@example.com' ) } "die of missing arguments";
lives_ok {
    $pkg->new(
        fmt => "unixref",
        doi => "10.1088/1126-6708/2009/03/112",
        usr => 'me@example.com',
    );
}
"I'm alive";
lives_ok {
    $pkg->new(
        doi => "10.1088/1126-6708/2009/03/112",
        usr => 'me@example.com',
    );
}
"I'm alive";

my $importer = $pkg->new(
    fmt => "unixref",
    doi => "10.1088/1126-6708/2009/03/112",
    usr => 'me@example.com',
);

isa_ok( $importer, $pkg );
can_ok( $importer, 'each' );

done_testing;
