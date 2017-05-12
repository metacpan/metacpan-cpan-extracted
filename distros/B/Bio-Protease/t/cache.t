use Modern::Perl;
use Test::More;
use Test::Exception;
use Time::HiRes 'time';

use_ok( 'Bio::Protease' );

my $p = Bio::Protease->new( specificity => 'trypsin', use_cache => 0 );
$p->digest( 'A' );

ok( !$p->_has_cache, "No cache when use_cache is off" );

my $c = Bio::Protease->new( specificity => 'trypsin', use_cache => 1 );
$c->digest( 'A' );

ok( $c->_has_cache, "Cache initialized when use_cache is on" );

my $test_seq = 'MAAEELRRVIKPR' x 10;

my $t0 = time();

$p->digest( $test_seq ) for (1..50);
my $time_no_caching = time() - $t0;

$t0 = time();

$c->digest( $test_seq ) for (1..50);
my $time_caching = time() - $t0;

cmp_ok( $time_no_caching, '>', $time_caching,
    "Caching should make things faster" );

# Custom caching
use Cache::Ref::Null;

lives_ok {
    Bio::Protease->new(
        specificity => 'trypsin',
        use_cache   => 1,
        cache       => Cache::Ref::Null->new
    );
};

done_testing();
