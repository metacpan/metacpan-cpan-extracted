use strict;
use warnings;

package App::Rssfilter::Feed::Test::RulesRanOverNewFeed;

use Test::Routine;
use Test::More;
use namespace::autoclean;
use Method::Signatures;

requires 'feed';
requires 'new_feed';

test rules_ran_over_new_feed => method {
    for my $rule ( @{ $self->feed->rules } ) {
        next if ! $rule->can( 'next_call' ); # mocks only
        my ( $name, $args ) = $rule->next_call;
        is( $name, 'constrain',          'rule was called ... ' );
        is( $args->[1], $self->new_feed, ' ... with the new feed' );
    }
};

1;
