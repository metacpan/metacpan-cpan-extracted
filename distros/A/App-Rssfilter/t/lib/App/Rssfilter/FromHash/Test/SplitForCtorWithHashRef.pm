use strict;
use warnings;

package App::Rssfilter::FromHash::Test::SplitForCtorWithHashRef;

use Test::Routine;
use Test::More;
use namespace::autoclean;
use Method::Signatures;

requires 'split_for_ctor';
requires 'fake_class';
requires 'results_of_split_for_ctor';

around 'split_for_ctor' => func( $orig, $self, @args ) {
    $orig->( $self, { castor => 'pollux', ajax => 'achilles' }, @args );
};

test split_for_ctor_with_hashref => method {
    is_deeply(
        { @{ shift @{ $self->results_of_split_for_ctor } } },
        { castor => 'pollux', ajax => 'achilles' },
        'returns the flattened hash reference'
    );
};

1;
