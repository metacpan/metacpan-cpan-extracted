use strict;
use Apache::Test;
use Apache::TestRequest;

plan tests => 4, have_lwp;

{
    my $body = GET_BODY "/euc-jp/index.html";
    ok($body, qr/charset:euc-jp/);
    ok($body, qr/charset_r:euc-jp/);
}

{
    my $body = GET_BODY "/utf-8/index.html";
    ok($body, qr/charset:utf-8/);
    ok($body, qr/charset_r:utf-8/);
}

