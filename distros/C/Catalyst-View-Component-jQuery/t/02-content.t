#!/usr/bin/env perl

use strict;
use warnings;
use Test::More 'no_plan';

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
BEGIN {
    use_ok('TestApp');
}

use Catalyst::Test 'TestApp';

my (
    $res,
    $got,
    $expected,
);

$res = request('/request_one');
$expected = <<'EOF';
request_one
<link type="text/css" href="jquery-ui.css" rel="stylesheet" media="all" />
<link type="text/css" href="superfish.css" rel="stylesheet" media="all" />
<script type="text/javascript" src="jquery.js"></script>
<script type="text/javascript" src="superfish.js"></script>
<script type="text/javascript">
//<![CDATA[
$(document).ready(function (){
$("#foobar").superfish();
});
//]]>
</script>
EOF
is($res->content, $expected, 'fetch page with all jQuery document elements');

$res = request('/request_two');
$expected = <<'EOF';
request_two
<link type="text/css" href="jquery-ui.css" rel="stylesheet" media="all" />
<link type="text/css" href="menu.css" rel="stylesheet" media="all" />
<script type="text/javascript" src="jquery.js"></script>
<script type="text/javascript" src="menu.js"></script>
<script type="text/javascript">
//<![CDATA[
$(document).ready(function (){
$("#foobar").mcDropdown("#foobar");
});
//]]>
</script>
EOF
is($res->content, $expected, 'fetch page with all jQuery elements but different jQuery plugins');

$res = request('/request_three');
$expected = <<'EOF';
request_three
<link type="text/css" href="jquery-ui.css" rel="stylesheet" media="all" />
<script type="text/javascript" src="jquery.js"></script>

EOF
is($res->content, $expected, 'fetch page, no plugin assets');

$res = request('/request_four');
# foobar
# barfoo
# foobaz
$expected = <<'EOF';
request_four
<link type="text/css" href="jquery-ui.css" rel="stylesheet" media="all" />
<link type="text/css" href="superfish.css" rel="stylesheet" media="all" />
<link type="text/css" href="menu.css" rel="stylesheet" media="all" />
<script type="text/javascript" src="jquery.js"></script>
<script type="text/javascript" src="superfish.js"></script>
<script type="text/javascript" src="menu.js"></script>
<script type="text/javascript">
//<![CDATA[
$(document).ready(function (){
$("#foobar").mcDropdown("#foobar");
$("#foobar").superfish();
$("#barfoo").superfish();
$("#foobaz").superfish({
foo : 42,
bar : $("div#vega")
});
});
//]]>
</script>
EOF
is($res->content, $expected, 'fetch page, multiple plugins, multiple cons');
