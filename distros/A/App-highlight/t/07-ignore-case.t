use strict;
use warnings;

use File::Basename;
use lib dirname(__FILE__);

use Test::More tests => 4;
use App::Cmd::Tester;
use Test::AppHighlightWords;

use App::highlight;

## default - matches are case sensitive
{
    open_words_txt_as_stdin('words_with_capitals.txt');

    my $result = test_app('App::highlight' => [ 'foo' ]);

    like($result->stdout, qr/^Foo Bar Baz$/ms, 'Foo Bar Baz - no match for "foo"');

    is($result->error, undef, 'threw no exceptions');

    restore_stdin();
}

## ignore-case - matches are case insensitive
{
    open_words_txt_as_stdin('words_with_capitals.txt');

    my $result = test_app('App::highlight' => [ '--ignore-case', 'foo' ]);

    like($result->stdout, qr/^.+Foo.+ Bar Baz$/ms, 'Foo Bar Baz - matched "foo" (ignore-case mode)');

    is($result->error, undef, 'threw no exceptions');

    restore_stdin();
}
