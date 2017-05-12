use strict;
use warnings;

package App::Rssfilter::FromHash::Test::SplitForCtorWithObject;

use Test::Routine;
use Test::More;
use namespace::autoclean;
use Method::Signatures;

requires 'split_for_ctor';
requires 'fake_class';
requires 'fake_class_name';
requires 'results_of_split_for_ctor';

has mock_object => (
    is => 'ro',
    lazy => 1,
    default => method {
        my $mock_object = Test::MockObject->new();
        $mock_object->set_isa( $self->fake_class_name );
        return $mock_object;
    },
);

around 'split_for_ctor' => func( $orig, $self, @args ) {
    $orig->( $self, $self->mock_object, @args );
};

test split_for_ctor_with_object => method {
    is_deeply(
        shift @{ $self->results_of_split_for_ctor },
        [ $self->mock_object ],
        'returns the already-constructed object',
    );
};

1;
