use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::ArXiv';
    use_ok $pkg;
}

require_ok $pkg;

lives_ok { $pkg->new( query => 'all:electron' ) };
lives_ok { $pkg->new( id    => '1408.6349,1408.6320,1408.6105' ) };
lives_ok {
    $pkg->new(
        query => 'all:electron',
        id    => '1408.6349,1408.6320,1408.6105'
    );
};

dies_ok { $pkg->new( start => 1, limit => 10 ) };

my $importer = $pkg->new( query => 'all:electron' );

isa_ok( $importer, $pkg );

can_ok( $importer, 'each' );

can_ok( $importer, 'count' );

done_testing;
