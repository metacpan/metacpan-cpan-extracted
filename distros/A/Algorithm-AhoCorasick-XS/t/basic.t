use strict;
use warnings;
use Test::More 0.96;

use Algorithm::AhoCorasick::XS;

subtest basic => sub {
    my $matcher = Algorithm::AhoCorasick::XS->new(['a', 'fai']);
    my @a = $matcher->matches('fa');
    is_deeply( \@a, ['a'] );

    @a = $matcher->matches('xxxx');
    is_deeply( \@a, [] );

    my $m = $matcher->first_match('fa');
    is( $m, 'a' );

    $m = $matcher->first_match('xxxx');
    is( $m, undef );
};

subtest unique_matches => sub {
    my $matcher = Algorithm::AhoCorasick::XS->new(['a']);
    my @a = $matcher->matches('aaaaa');
    is_deeply( \@a, ['a', 'a', 'a', 'a', 'a'] );

    @a = $matcher->unique_matches('aaaaa');
    is_deeply( \@a, ['a'] );

    @a = $matcher->matches('xxxxx');
    is_deeply( \@a, [] );

    @a = $matcher->unique_matches('xxxxx');
    is_deeply( \@a, [] );
};

done_testing;
