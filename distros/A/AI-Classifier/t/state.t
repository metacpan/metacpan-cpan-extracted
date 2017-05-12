
use strict;
use Test::More tests => 6;
use AI::Classifier::Text;
use AI::NaiveBayes::Learner;
use File::Spec;
ok(1); # If we made it this far, we're loaded.

my $lr = AI::NaiveBayes::Learner->new(purge => 0);

$lr->add_example(attributes => _hash(qw(sheep very valuable farming)),
		          labels => ['farming'] );
is $lr->examples, 1;

my $nb = $lr->classifier;
ok $nb;


my $tp = AI::Classifier::Text->new( classifier => $nb );
# Save
my $file = File::Spec->catfile('t', 'model.dat');
$tp->store($file);
is -e $file, 1;

# Restore
$tp = AI::Classifier::Text->load($file);
ok $tp;
isa_ok( $tp, 'AI::Classifier::Text' );


################################################################
sub _hash { +{ map {$_,1} @_ } }
