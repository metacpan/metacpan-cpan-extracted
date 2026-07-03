#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Algorithm::Classifier::NaiveBayes;

my $nb = Algorithm::Classifier::NaiveBayes->new;
$nb->train( 'spam', 'buy cheap pills now cheap' );
$nb->train( 'ham',  'meeting at noon tomorrow' );
$nb->train( 'ham',  'lunch meeting tomorrow' );

is( $nb->{'model'}{'total_docs'},                     3, 'total_docs incremented per train call' );
is( $nb->{'model'}{'class_counts'}{'spam'},           1, 'class_counts for spam' );
is( $nb->{'model'}{'class_counts'}{'ham'},            2, 'class_counts for ham' );
is( $nb->{'model'}{'class_totals'}{'spam'},           5, 'class_totals counts tokens' );
is( $nb->{'model'}{'token_counts'}{'spam'}{'cheap'},  2, 'token_counts counts repeats' );
is( $nb->{'model'}{'token_counts'}{'ham'}{'meeting'}, 2, 'token_counts across docs' );
ok( !exists $nb->{'model'}{'token_counts'}{'spam'}{''}, 'no empty token trained' );
is( scalar keys %{ $nb->{'model'}{'tokens'} }, 9, 'vocabulary size across classes' );

# binary token weighting counts each unique token once per document
my $bin = Algorithm::Classifier::NaiveBayes->new( 'token_weighting' => 'binary' );
$bin->train( 'spam', 'cheap cheap cheap pills' );
is( $bin->{'model'}{'token_counts'}{'spam'}{'cheap'}, 1, 'binary weighting counts repeated tokens once' );
is( $bin->{'model'}{'class_totals'}{'spam'},          2, 'binary weighting class_totals count unique tokens' );
$bin->train( 'spam', 'cheap watches' );
is( $bin->{'model'}{'token_counts'}{'spam'}{'cheap'}, 2, 'binary weighting still counts across documents' );

# undef class or text dies
eval { $nb->train( undef, 'foo bar' ); };
like( $@, qr/No class specified/, 'train with a undef class dies' );

eval { $nb->train('spam'); };
like( $@, qr/No text specified/, 'train with undef text dies' );
is( $nb->{'model'}{'total_docs'}, 3, 'model unchanged after undef text train' );

done_testing;
