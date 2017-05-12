use strict;
use warnings;
use Test::More 0.96;
use Algorithm::AhoCorasick::XS;

subtest no_words => sub {
    my $matcher = Algorithm::AhoCorasick::XS->new([]);
    is_deeply( [ $matcher->matches("") ], [] );
    is_deeply( [ $matcher->matches("xxx") ], [] );
};

subtest no_input => sub {
    my $matcher = Algorithm::AhoCorasick::XS->new(["foo", "bar", "baz"]);
    is_deeply( [ $matcher->matches("") ], [] );
    is_deeply( [ $matcher->matches(undef) ], [] );
};

subtest duplicate_words => sub {
    my $matcher = Algorithm::AhoCorasick::XS->new(["aa", "aa"]);
    is_deeply( [ $matcher->matches("aa") ], ["aa", "aa"], 'one result for each dupe' );
    is_deeply( [ $matcher->matches("aaa") ], ["aa", "aa", "aa", "aa"] );
};

subtest accidentally_sent_list => sub {
    eval {
        my $matcher = Algorithm::AhoCorasick::XS->new("foo", "bar", "baz");
    };
    like ($@, qr/^Usage:/, 'rejects a list');
};

done_testing;
