use strict;
use warnings;

package App::Rssfilter::FromHash::Test::SplitForCtor;

use Test::Routine;
use Test::Exception;
use namespace::autoclean;
use Method::Signatures;

requires 'split_for_ctor';
requires 'results_of_split_for_ctor';

test call_split_for_ctor => method {
    lives_ok(
        sub {
            my @results = $self->split_for_ctor;
            push @{ $self->results_of_split_for_ctor }, @results;
        },
        'can call split_for_ctor without calamity'
    );
};

1;
