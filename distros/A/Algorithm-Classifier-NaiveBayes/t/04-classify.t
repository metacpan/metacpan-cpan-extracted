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

is( $nb->classify('buy cheap pills'),       'spam', 'classifies spam' );
is( $nb->classify('meeting noon tomorrow'), 'ham',  'classifies ham' );

my ( $best, $scores, $probs ) = $nb->classify('cheap pills');
is( $best,        'spam', 'list context returns best class' );
is( ref($scores), 'HASH', 'list context returns scores hashref' );
is_deeply( [ sort keys %{$scores} ], [ 'ham', 'spam' ], 'scores has an entry per class' );
ok( $scores->{'spam'} > $scores->{'ham'}, 'winning class has the highest score' );
ok( $scores->{'spam'} < 0,                'scores are log probabilities' );

# probabilities
is( ref($probs), 'HASH', 'list context returns probs hashref' );
is_deeply( [ sort keys %{$probs} ], [ 'ham', 'spam' ], 'probs has an entry per class' );
ok( $probs->{'spam'} > $probs->{'ham'},                   'winning class has the highest probability' );
ok( abs( $probs->{'spam'} + $probs->{'ham'} - 1 ) < 1e-9, 'probabilities sum to 1' );
ok( $probs->{'spam'} > 0 && $probs->{'spam'} <= 1,        'probabilities are between 0 and 1' );
ok( $probs->{'ham'} > 0,                                  'losing class probability is greater than 0' );

# unseen tokens are smoothed rather than dying
my $unseen = $nb->classify('zebra quantum');
ok( defined($unseen), 'classify handles entirely unseen tokens' );

# untrained model
my $empty = Algorithm::Classifier::NaiveBayes->new;
is( $empty->classify('anything'), undef, 'untrained classify returns undef' );
my ( $ebest, $escores, $eprobs ) = $empty->classify('anything');
is( $ebest, undef, 'untrained classify returns undef in list context' );
is_deeply( $escores, {}, 'untrained classify returns empty scores' );
is_deeply( $eprobs,  {}, 'untrained classify returns empty probs' );

# tie breaking is deterministic
my $tie = Algorithm::Classifier::NaiveBayes->new;
$tie->train( 'b', 'foo' );
$tie->train( 'a', 'foo' );
is( $tie->classify('foo'), 'a', 'ties break deterministically by class name' );

# tied classes have equal probabilities
my ( $tbest, $tscores, $tprobs ) = $tie->classify('foo');
ok( abs( $tprobs->{'a'} - 0.5 ) < 1e-9, 'tied classes split the probability evenly' );

# lidstone smoothing
# one class, two trained tokens, so a unseen token scores
# log( (0 + alpha) / (2 + alpha * 2) )
my $lid = Algorithm::Classifier::NaiveBayes->new( 'smoothing' => 'lidstone', 'alpha' => 0.5 );
$lid->train( 'only', 'aa bb' );
my ( $lbest, $lscores ) = $lid->classify('cc');
ok( abs( $lscores->{'only'} - log( 0.5 / 3 ) ) < 1e-9, 'lidstone alpha is used in smoothing' );

my $lap = Algorithm::Classifier::NaiveBayes->new;
$lap->train( 'only', 'aa bb' );
my ( $lapbest, $lapscores ) = $lap->classify('cc');
ok( abs( $lapscores->{'only'} - log( 1 / 4 ) ) < 1e-9, 'laplace smoothing unchanged' );

# binary token weighting dedupes the text being classified
# one class trained "aa bb", so classifying "aa aa" binary scores
# log( (1 + 1) / (2 + 2) ) for the single deduped aa
my $bin = Algorithm::Classifier::NaiveBayes->new( 'token_weighting' => 'binary' );
$bin->train( 'only', 'aa bb' );
my ( $binbest, $binscores ) = $bin->classify('aa aa');
ok( abs( $binscores->{'only'} - log( 2 / 4 ) ) < 1e-9, 'binary weighting dedupes tokens when classifying' );

# uniform priors
# with no tokens the score is just the prior, so a unbalanced training
# set shows the difference between trained and uniform priors
my $trained_priors = Algorithm::Classifier::NaiveBayes->new;
$trained_priors->train( 'a', 'xx' );
$trained_priors->train( 'a', 'yy' );
$trained_priors->train( 'b', 'xx' );
my ( $tpbest, $tpscores ) = $trained_priors->classify('');
ok( abs( $tpscores->{'a'} - log( 2 / 3 ) ) < 1e-9, 'trained priors reflect training balance' );

my $uniform_priors = Algorithm::Classifier::NaiveBayes->new( 'priors' => 'uniform' );
$uniform_priors->train( 'a', 'xx' );
$uniform_priors->train( 'a', 'yy' );
$uniform_priors->train( 'b', 'xx' );
my ( $upbest, $upscores ) = $uniform_priors->classify('');
ok( abs( $upscores->{'a'} - log( 1 / 2 ) ) < 1e-9,     'uniform priors are log(1/classes)' );
ok( abs( $upscores->{'a'} - $upscores->{'b'} ) < 1e-9, 'uniform priors are equal for every class' );

done_testing;
