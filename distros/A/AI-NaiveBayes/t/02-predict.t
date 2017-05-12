use strict;
use warnings;
use Test::More tests => 12;
use AI::NaiveBayes;
use AI::NaiveBayes::Learner;
ok(1); # If we made it this far, we're loaded.

my $lr = AI::NaiveBayes::Learner->new();

# Populate
$lr->add_example( attributes => _hash(qw(sheep very valuable farming)),
           labels => ['farming'] );
$lr->add_example( attributes => _hash(qw(farming requires many kinds animals)),
           labels => ['farming'] );
$lr->add_example( attributes => _hash(qw(vampires drink blood vampires may staked)),
           labels => ['vampire'] );
$lr->add_example( attributes => _hash(qw(vampires cannot see their images mirrors)),
           labels => ['vampire'] );

my $classifier = $lr->classifier;
ok $classifier;

# Predict
my $s = $classifier->classify( _hash(qw(i would like to begin farming sheep)) );
my $h = $s->label_sums;
ok $h;
ok $h->{farming} > 0.5;
ok $h->{vampire} < 0.5;

$s = $classifier->classify( _hash(qw(i see that many vampires may have eaten my beautiful daughter's blood)) );
$h = $s->label_sums;
ok $h;
ok $h->{farming} < 0.5;
ok $h->{vampire} > 0.5;

# Find predictors

my $p = $classifier->classify( _hash( qw(i would like to begin farming sheep)) );
my( $best_cat, @predictors ) = $p->find_predictors();
is( $best_cat, 'farming', 'Best category' );
is( scalar @predictors, 2, 'farming and sheep - two predictors' );
is( $predictors[0][0], 'farming', 'Farming is the best predictor' );

# Prior probs
$lr = AI::NaiveBayes::Learner->new();

# Populate
$lr->add_example( attributes => _hash(qw(sheep very valuable farming)),
           labels => ['farming'] );
$lr->add_example( attributes => _hash(qw(farming requires many kinds animals)),
           labels => ['farming'] );
$lr->add_example( attributes => _hash(qw(good soil)),
           labels => ['farming'] );
$lr->add_example( attributes => _hash(qw(vampires drink blood vampires may staked)),
           labels => ['vampire'] );

$classifier = $lr->classifier;

# Predict
$s = $classifier->classify( _hash(qw(jakis tekst po polsku)) );
$h = $s->label_sums;
ok(abs( 3 - $h->{farming} / $h->{vampire} ) < 0.01, 'Prior probabillities' );


################################################################
sub _hash { +{ map {$_,1} @_ } }
