#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Algorithm::Classifier::NaiveBayes;

my $nb = Algorithm::Classifier::NaiveBayes->new;

is_deeply( [ $nb->classes ], [], 'classes is empty on a new object' );

eval { $nb->class_tokens('spam'); };
like( $@, qr/does not exist/, 'class_tokens of a unknown class dies' );

eval { $nb->class_tokens(); };
like( $@, qr/No class specified/, 'class_tokens with no class dies' );

$nb->train( 'spam', 'buy cheap pills now cheap' );
$nb->train( 'ham',  'meeting at noon tomorrow' );

is_deeply( [ $nb->classes ],              [ 'ham', 'spam' ], 'classes returns trained classes sorted' );
is_deeply( [ $nb->class_tokens('spam') ], [ 'buy', 'cheap',   'now',  'pills' ], 'class_tokens returns sorted tokens' );
is_deeply( [ $nb->class_tokens('ham') ],  [ 'at',  'meeting', 'noon', 'tomorrow' ], 'class_tokens per class' );

# untraining a class removes it from the listings
$nb->untrain( 'ham', 'meeting at noon tomorrow' );
is_deeply( [ $nb->classes ], ['spam'], 'untrained classes are no longer listed' );
eval { $nb->class_tokens('ham'); };
like( $@, qr/does not exist/, 'class_tokens of a untrained class dies' );

done_testing;
