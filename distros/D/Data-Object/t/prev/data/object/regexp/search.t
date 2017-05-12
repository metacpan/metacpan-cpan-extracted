use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Regexp';
can_ok 'Data::Object::Regexp', 'search';

subtest 'test search with no capturing' => sub {
    my $re     = Data::Object::Regexp->new(qr(test));
    my $result = $re->search('this is a test of matching');

    isa_ok $result, 'Data::Object::Regexp::Result';

    is $result->string, 'this is a test of matching', 'result string()';
    is $result->matched, 'test', 'result matched()';
    is $result->regexp->data, $re->data, 'result regexp()';
    is $result->prematched, 'this is a ', 'result prematch()';
    is $result->postmatched, ' of matching', 'result postmatch()';

    ok ! $re->search('this does not match')->count,
        'match returns false for non-matching string';
};

subtest 'test search with captures' => sub {
    my $re     = Data::Object::Regexp->new(qr((\w+)\s+(\w+)));
    my $result = $re->search('two words');

    isa_ok $result, 'Data::Object::Regexp::Result';
    is_deeply $result->captures, [qw(two words)], 'captured two matches';
    is_deeply $result->named_captures, {}, 'no named matches';

    $result = $re->search('here are more words to match');
    is_deeply $result->captures, [qw(here are)],
        'captured two matches with longer string';

    $result = $re->search('nope');
    ok ! $result->count, 'non-matching string returns false';
};

subtest 'test search with named captures' => sub {
    my $re     = Data::Object::Regexp->new(qr{(?<first>foo).*(?<second>bar)});
    my $result = $re->search('this string has foo and bar');

    is_deeply $result->named_captures->data,
        { first => ['foo'], second => ['bar'] },
        'matched both named captures';
    is_deeply $result->named_captures->keys->sort->data,
        ['first', 'second'], 'named_captures()';

    is $result->named_captures->get('first')->first, 'foo', 'capture named foo';
    is $result->named_captures->get('second')->first, 'bar', 'capture named foo';
    ok ! $result->named_captures->get('bogus'), 'capture named bogus';
};

ok 1 and done_testing;
