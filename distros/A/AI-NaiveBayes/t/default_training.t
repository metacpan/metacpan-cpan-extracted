use strict;
use Test::More tests => 2;
use AI::NaiveBayes;
ok(1); # If we made it this far, we're loaded.

my $classifier = AI::NaiveBayes->train( 
    {
        attributes => _hash(qw(sheep very valuable farming)),
        labels => ['farming']
    },
    {
        attributes => _hash(qw(vampires cannot see their images mirrors)),
        labels => ['vampire']
    },
);

isa_ok( $classifier, 'AI::NaiveBayes' );


################################################################
sub _hash { +{ map {$_,1} @_ } }

