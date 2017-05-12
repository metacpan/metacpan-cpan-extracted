use strict;
use Apache::Test;
use Apache::TestRequest;

plan tests => 3, have_lwp;

{
    my $body = GET_BODY "/test.html";
    ok($body, qr/It's a module/);
}

{
    my $body = GET_BODY "/test.html.js";
    ok($body, qr/document\.writeln/);
    ok($body, qr/It&#x27;s a module/);
}
