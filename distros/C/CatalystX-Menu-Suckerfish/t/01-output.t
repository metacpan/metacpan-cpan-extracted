#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use Test::More 'no_plan';

use Catalyst::Test 'TestApp';

my $res = request('/menu');
is($res->content, <<EOF, 'fetch correct UL element');
<ul class="navmenu" id="navlist">
    <li><span class="menulabel">Main</span><ul>
            <li title="A public function"><a href="http://localhost/public">Public</a></li>
        </ul>
    </li>
    <li title="About us"><a href="http://localhost/about/us">About us</a></li>
</ul>
EOF

# for Filament Group iPod menu
# UL wrapped in DIV
# text-only elements wrapped in A elements
$res = request('/menu_in_div');
my @expected = (
<<EOF,
<div id="divid" class="hidden">
    <ul>
        <li><a href="#">Main</a><ul>
                <li><a href="http://localhost/public">Public</a></li>
            </ul>
        </li>
        <li><a href="http://localhost/about/us">About us</a></li>
    </ul>
</div>
EOF
<<EOF,
<div class="hidden" id="divid">
    <ul>
        <li><a href="#">Main</a><ul>
                <li><a href="http://localhost/public">Public</a></li>
            </ul>
        </li>
        <li><a href="http://localhost/about/us">About us</a></li>
    </ul>
</div>
EOF
);
my $got = $res->content;
ok($got eq $expected[0] || $got eq $expected[1], 'fetch correct UL element');

