use strict;
use warnings;
use Test::Base;
use FindBin;
use lib "$FindBin::Bin/lib";
use HTTP::Request::Common;

plan tests => 1 + 1 * blocks;

use_ok('Catalyst::Test', 'TestApp');

run {
    my $block = shift;
    my $res = request(
        POST '/htmlspecialchars_test',
        User_Agent => $block->user_agent,
        Content    => [ content_type => $block->content_type ],
    );
    is(
        $res->content,
        $block->expected,
        $block->name
    );
}

__DATA__
=== text/plain
--- user_agent: DoCoMo/2.0 SH902i(c100;TB;W24H12)
--- content_type: text/plain
--- expected: (>３<)

=== text/html
--- user_agent: DoCoMo/2.0 SH902i(c100;TB;W24H12)
--- content_type: text/html
--- expected: (&gt;３&lt;)
