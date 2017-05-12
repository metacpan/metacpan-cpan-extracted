use strict;
use warnings;

package App::Rssfilter::Feed::Test::RulesRanOverOldFeed;

use Test::Routine;
use Test::More;
use namespace::autoclean;
use Method::Signatures;

requires 'feed';
requires 'old_feed';

test rules_ran_over_old_feed => method {
    for my $rule ( @{ $self->feed->rules } ) {
        next if ! $rule->can( 'next_call' ); # mocks only
        my ( $name, $args ) = $rule->next_call;
        is( $name, 'constrain',          'rule was called ... ' );
        is( $args->[1], $self->old_feed, ' ... with the old feed' );
    }
};

1;
