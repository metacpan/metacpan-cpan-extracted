use strict;
use warnings;
use Test::More tests => 11;
use AI::NaiveBayes::Learner;
ok(1); # If we made it this far, we're loaded.

my $learner = AI::NaiveBayes::Learner->new();

# Populate
$learner->add_example( attributes => _hash(qw(sheep very valuable farming)),
		   labels => ['farming'] );
is $learner->{labels}{farming}{count}, 1;

$learner->add_example( attributes => _hash(qw(farming requires many kinds animals)),
		   labels => ['farming'] );
is $learner->{labels}{farming}{count}, 2;
is keys %{$learner->{labels}}, 1;

$learner->add_example( attributes => _hash(qw(vampires drink blood vampires may staked)),
		   labels => ['vampire'] );
is $learner->{labels}{vampire}{count}, 1;

$learner->add_example( attributes => _hash(qw(vampires cannot see their images mirrors)),
		   labels => ['vampire'] );
is $learner->{labels}{vampire}{count}, 2;
is keys %{$learner->{labels}}, 2;

# features_kept > 1
$learner = AI::NaiveBayes::Learner->new(features_kept => 5);
$learner->add_example( attributes => _hash(qw(one two three four)),
		   labels => ['farming'] );
$learner->add_example( attributes => _hash(qw(five six seven eight)),
		   labels => ['farming'] );
$learner->add_example( attributes => _hash(qw(one two three four five)),
		   labels => ['farming'] );
my $model = $learner->classifier->model;
is keys %{$model->{probs}{farming}}, 5, '5 features kept';
is join(" ", sort { $a cmp $b } keys %{$model->{probs}{farming}}), 'five four one three two';

# features_kept < 1
$learner = AI::NaiveBayes::Learner->new(features_kept => 0.5);
$learner->add_example( attributes => _hash(qw(one two three four)),
		   labels => ['farming'] );
$learner->add_example( attributes => _hash(qw(five six seven eight)),
		   labels => ['farming'] );
$learner->add_example( attributes => _hash(qw(one two three four)),
		   labels => ['farming'] );
$model = $learner->classifier->model;
is keys %{$model->{probs}{farming}}, 4, 'half features kept';
is join(" ", sort { $a cmp $b } keys %{$model->{probs}{farming}}), 'four one three two';

sub _hash { +{ map {$_,1} @_ } }
