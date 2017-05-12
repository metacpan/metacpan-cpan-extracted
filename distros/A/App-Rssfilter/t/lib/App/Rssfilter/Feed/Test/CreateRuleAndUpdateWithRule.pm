use strict;
use warnings;

package App::Rssfilter::Feed::Test::CreateRuleAndUpdateWithRule;

use Test::Routine;
use Test::Exception;
use namespace::autoclean;
use Method::Signatures;

requires 'feed';

has new_mock_rule => (
    is => 'ro',
    default => sub {
        my $new_mock_rule = Test::MockObject->new;
        $new_mock_rule->set_always( 'constrain', 1 );
        $new_mock_rule->set_isa( 'App::Rssfilter::Rule' );
        return $new_mock_rule;
    },
);

test update_with_rule => method {
    lives_ok(
        sub { $self->feed->update( rules => [ $self->new_mock_rule ] ); },
        'can pass rules to update when a feed already has rules'
    );
    push @{ $self->feed->rules }, $self->new_mock_rule;
};

1;
