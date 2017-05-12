use strict;
use warnings;
use Test::Base;
use FindBin;
use lib "$FindBin::Bin/lib";
use HTTP::Request::Common;

plan tests => 1 + 1 * blocks;

use_ok('Catalyst::Test', 'TestApp');

filters {
    input => [qw( eval )],
};

run {
    my $block = shift;
    my $res = request(
        POST '/param_test',
        User_Agent => $block->user_agent,
        Content    => [ text => $block->input ],
    );
    is(
        $res->content,
        join('/', $block->encoding, $block->internal, $block->input),
        $block->name . ' - ' . $block->comment
    );
}

__DATA__
=== xhtml_compliant docomo
--- user_agent: DoCoMo/2.0 SH902i(c100;TB;W24H12)
--- input: "\xE3\x81\x82\xEE\x98\xBE"
--- comment: [あ][DoCoMoの太陽](utf8)
--- encoding: x-utf8-docomo
--- internal: &#x3042;&#xe63e;

=== non xhtml_compliant docomo
--- user_agent: DoCoMo/1.0/F505i/c20/TB/W20H10
--- input: "\x82\xA0\xF8\x9F"
--- comment: [あ][DoCoMoの太陽](sjis)
--- encoding: x-sjis-docomo
--- internal: &#x3042;&#xe63e;

=== au
--- user_agent: KDDI-SA31 UP.Browser/6.2.0.6.3.129 (GUI) MMP/2.0
--- input: "\x82\xA0\xF6\x60"
--- comment: [あ][auの太陽](sjis)
--- encoding: x-sjis-kddi-auto
--- internal: &#x3042;&#xef60;

=== 3gc softbank
--- user_agent: SoftBank/1.0/821T/TJ001/SN*************** Browser/NetFront/3.3
--- input: "\xE3\x81\x82\xEE\x81\x8A"
--- comment: [あ][softbankの太陽](utf8)
--- encoding: x-utf8-softbank
--- internal: &#x3042;&#xe04a;

=== non 3gc softbank
--- user_agent: J-PHONE/2.0/J-T04
--- input: "\x82\xA0\x1B\x24\x47\x6A\x0F"
--- comment: [あ][softbankの太陽ウェブコード](sjis)
--- encoding: x-sjis-softbank
--- internal: &#x3042;&#xe04a;

=== non mobile
--- user_agent: Mozilla/5.0
--- input: "\xE3\x81\x82"
--- comment: [あ](utf8)
--- encoding: utf-8-strict
--- internal: &#x3042;
