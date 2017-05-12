use strict;
use warnings;

use Test::More tests => 6;

use_ok('Bot::Net::Util');

{
    # plain
    my @split = Bot::Net::Util->parse_bot_command("this is a test");
    is_deeply(\@split, [ qw/ this is a test / ], 'this is a test');
}

{
    # double-quotes
    my @split = Bot::Net::Util->parse_bot_command(q{
        this "is a" test
    });
    is_deeply(\@split, [ 'this', 'is a', 'test' ], 'this "is a" test');
}

{
    # single-quotes
    my @split = Bot::Net::Util->parse_bot_command(q{
        this 'is a' test
    });
    is_deeply(\@split, [ 'this', 'is a', 'test' ], "this 'is a' test");
}

{
    # double-quotes escaped
    my @split = Bot::Net::Util->parse_bot_command(q{
        this """is a""" test
    });
    is_deeply(\@split, [ 'this', '"is a"', 'test' ], 'this """is a""" test');
}

{
    # single-quotes escaped
    my @split = Bot::Net::Util->parse_bot_command(q{
        this '''is a''' test
    });
    is_deeply(\@split, [ 'this', "'is a'", 'test' ], "this '''is a''' test");
}
