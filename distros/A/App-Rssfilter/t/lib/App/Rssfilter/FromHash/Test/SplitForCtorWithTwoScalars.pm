use strict;
use warnings;

package App::Rssfilter::FromHash::Test::SplitForCtorWithTwoScalars;

use Test::Routine;
use Test::More;
use namespace::autoclean;
use Method::Signatures;
use Test::MockObject;

requires 'split_for_ctor';
requires 'results_of_split_for_ctor';

around 'split_for_ctor' => func( $orig, $self, @args ) {
    $orig->( $self, lol => 'wut', @args );
};

test split_for_ctor_with_two_scalars => method {
    is_deeply(
        shift @{ $self->results_of_split_for_ctor },
        [ qw< lol wut > ],
        'returns two scalars as a array ref containing the same two scalars'
    );
};

1;
