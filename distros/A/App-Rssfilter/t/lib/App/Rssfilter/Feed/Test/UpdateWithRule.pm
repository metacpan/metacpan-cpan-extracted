use strict;
use warnings;

package App::Rssfilter::Feed::Test::UpdateWithRule;

use Test::Routine;
use Test::Exception;
use namespace::autoclean;
use Method::Signatures;

requires 'feed';
requires 'mock_rule';

test update_with_rule => method {
    lives_ok(
        sub { $self->feed->update( rules => [ $self->mock_rule ] ); },
        'passed rules as parameter to update'
    );
    push @{ $self->feed->rules }, $self->mock_rule;
};

1;
