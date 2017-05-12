use strict;
use Apache::Test;
use Apache::TestRequest;

plan tests => 2, have_lwp;

{
    my $head = GET_HEAD "/mod";
    ok($head, qr@Content-Type: text/html; charset=euc-kr@);

    my $body = GET_BODY "/mod";
    ok($body, qr/charset:euc-kr/);
}
