#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 2;

use Catalyst::Test 'TestApp';

my $res = request('/menu');
is($res->content, <<EOF, 'fetch correct UL element');
<ul class="mcdropdown_menu" id="navlist">
    <li rel="Main">Main<ul>
            <li rel="http://localhost/public">Public</li>
        </ul>
    </li>
    <li rel="http://localhost/about/us">About us</li>
</ul>
EOF

$res = request('/big_menu');
is($res->content, <<EOF, 'fetch correct UL element, bigger menu');
<ul class="mcdropdown_menu" id="navlist">
    <li rel="http://localhost/about/us">About us</li>
    <li rel="Customer">Customer<ul>
            <li rel="http://localhost/accounts">Accounts</li>
            <li rel="http://localhost/orders">Orders</li>
        </ul>
    </li>
    <li rel="Main">Main<ul>
            <li rel="http://localhost/public">Public</li>
        </ul>
    </li>
</ul>
EOF

__END__
# test got:
# <ul class="mcdropdown_menu" id="navlist">
#     <li rel="http://localhost/about/us">About us</li>
#     <li rel="Customer">Customer<ul>
#             <li rel="http://localhost/accounts">Customer accounts</li>
#             <li rel="http://localhost/orders">Customer orders</li>
#         </ul>
#     </li>
#     <li rel="Main">Main<ul>
#             <li rel="http://localhost/public">A public function</li>
#         </ul>
#     </li>
# </ul>
