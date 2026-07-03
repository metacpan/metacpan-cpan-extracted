#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Storable;

use Algorithm::Classifier::NaiveBayes;

my $un = Algorithm::Classifier::NaiveBayes->new;
$un->train( 'spam', 'buy cheap pills now cheap' );
$un->train( 'ham',  'meeting at noon tomorrow' );
$un->train( 'ham',  'lunch meeting tomorrow' );

$un->untrain( 'ham', 'lunch meeting tomorrow' );
is( $un->{'model'}{'total_docs'},                     2, 'untrain decrements total_docs' );
is( $un->{'model'}{'class_counts'}{'ham'},            1, 'untrain decrements class_counts' );
is( $un->{'model'}{'class_totals'}{'ham'},            4, 'untrain decrements class_totals' );
is( $un->{'model'}{'token_counts'}{'ham'}{'meeting'}, 1, 'untrain decrements token_counts' );
ok( !exists $un->{'model'}{'token_counts'}{'ham'}{'lunch'}, 'zeroed tokens are removed from the class' );
ok( !exists $un->{'model'}{'tokens'}{'lunch'},              'tokens in no class are removed from the vocabulary' );
ok( exists $un->{'model'}{'tokens'}{'meeting'},             'tokens still in a class stay in the vocabulary' );

# untraining the last document of a class removes the class
$un->untrain( 'ham', 'meeting at noon tomorrow' );
ok( !exists $un->{'model'}{'class_counts'}{'ham'}, 'empty classes are removed from class_counts' );
ok( !exists $un->{'model'}{'token_counts'}{'ham'}, 'empty classes are removed from token_counts' );
ok( !exists $un->{'model'}{'class_totals'}{'ham'}, 'empty classes are removed from class_totals' );
is( $un->{'model'}{'total_docs'},  1,      'total_docs correct after class removal' );
is( $un->classify('meeting noon'), 'spam', 'classify no longer sees the removed class' );

# untraining an unknown class is a noop
$un->untrain( 'nonexistent', 'foo bar' );
is( $un->{'model'}{'total_docs'}, 1, 'untraining an unknown class is a noop' );

# undef class or text dies
eval { $un->untrain( undef, 'foo bar' ); };
like( $@, qr/No class specified/, 'untrain with a undef class dies' );

eval { $un->untrain('spam'); };
like( $@, qr/No text specified/, 'untrain with undef text dies' );
is( $un->{'model'}{'total_docs'}, 1, 'model unchanged after undef text untrain' );

# untraining more than was trained does not go negative
$un->untrain( 'spam', 'buy cheap pills now cheap' );
$un->untrain( 'spam', 'buy cheap pills now cheap' );
is( $un->{'model'}{'total_docs'}, 0, 'repeated untrain does not go negative' );
is_deeply( $un->{'model'}{'tokens'}, {}, 'vocabulary empty after untraining everything' );
is( $un->classify('anything'), undef, 'fully untrained model classifies as undef' );

# train then untrain returns the model to its prior state
my $rt = Algorithm::Classifier::NaiveBayes->new;
$rt->train( 'spam', 'buy cheap pills' );
my $before = Storable::dclone( $rt->{'model'} );
$rt->train( 'ham', 'meeting at noon' );
$rt->untrain( 'ham', 'meeting at noon' );
is_deeply( $rt->{'model'}, $before, 'untrain restores the model to its pre-train state' );

# binary weighting untrains each unique token once, so train then
# untrain still round trips
my $bin = Algorithm::Classifier::NaiveBayes->new( 'token_weighting' => 'binary' );
$bin->train( 'spam', 'cheap pills' );
my $bin_before = Storable::dclone( $bin->{'model'} );
$bin->train( 'spam', 'cheap cheap cheap watches' );
$bin->untrain( 'spam', 'cheap cheap cheap watches' );
is_deeply( $bin->{'model'}, $bin_before, 'binary weighting untrain restores the model' );

done_testing;
