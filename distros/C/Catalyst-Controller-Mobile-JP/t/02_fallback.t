use strict;
use warnings;
use Test::Base;
use FindBin;
use lib "$FindBin::Bin/lib";
use HTTP::Request::Common;

plan tests => 1 + 1 * blocks;

use_ok('Catalyst::Test', 'TestApp');

filters {
    expected => [qw( eval )],
};

run {
    my $block = shift;
    my $res = request(
        POST '/fallback_test',
        User_Agent => $block->user_agent,
    );
    is(
        $res->content,
        $block->expected,
        $block->name
    );
}

__DATA__
=== xhtml_compliant docomo
--- user_agent: DoCoMo/2.0 SH902i(c100;TB;W24H12)
--- expected: "\xEE\x9B\x91[EZ][WC]"

=== au
--- user_agent: KDDI-SA31 UP.Browser/6.2.0.6.3.129 (GUI) MMP/2.0
--- expected: "\x81\x6d\x82\x89\x83\x82\x81\x5b\x83\x68\x81\x6e\xF7\x94[WC]"

=== 3gc softbank
--- user_agent: SoftBank/1.0/821T/TJ001/SN*************** Browser/NetFront/3.3
--- expected: "［ｉモード］[EZ]\xEE\x8C\x89"
