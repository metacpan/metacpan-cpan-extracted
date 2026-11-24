# Regression tests for the header()/redirect() security fixes in CGI.pm 5.02,
# ported to psgi_header/psgi_redirect.

use strict;
use warnings;

use Test::More;

use CGI;
use CGI::PSGI;
use CGI::Cookie;

my $env = {
    REQUEST_METHOD  => 'GET',
    QUERY_STRING    => '',
    SCRIPT_NAME     => '/app',
    SERVER_PROTOCOL => 'HTTP/1.0',
    SERVER_PORT     => 80,
    SERVER_NAME     => 'example.com',
    'psgi.input'    => \*STDIN,
};

my $q = CGI::PSGI->new($env);

sub headers_of { my(undef, $h) = @_; return $h }

sub header_value {
    my($headers, $name) = @_;
    my @h = @$headers;
    my @v;
    while (my($k, $v) = splice @h, 0, 2) { push @v, $v if $k eq $name }
    return wantarray ? @v : $v[0];
}

# CVE-2026-120639: values are not HTML unescaped after the newline check
{
    my $h = headers_of $q->psgi_header('text/plain', '200', (undef) x 7,
                                       'X-Test=a&#13;&#10;Set-Cookie: evil=1');
    is header_value($h, 'X-test'), 'a&#13;&#10;Set-Cookie: evil=1',
        'positional extra header kept verbatim';
    unlike join('', @$h), qr/[\r\n]/, 'no raw newline from entities';

    $h = headers_of $q->psgi_header(-x_test => 'a&#13;&#10;b');
    is header_value($h, 'X-test'), 'a&#13;&#10;b', 'named extra header kept verbatim';

    local $CGI::Q = CGI->new({});
    $CGI::Q->autoEscape(0);
    $h = headers_of $q->psgi_header(-x_test => 'a&#10;b');
    is header_value($h, 'X-test'), 'a&#10;b', 'named extra header verbatim with autoEscape off';

    $h = headers_of $q->psgi_header(-x_test => 'a &amp; "b"');
    is header_value($h, 'X-test'), 'a &amp; "b"', 'entities and quotes in named values kept';

    $h = headers_of $q->psgi_header(-x_test => '');
    is header_value($h, 'X-test'), '', 'empty named value stays empty';

    $h = headers_of $q->psgi_header(-x_foo_bar => 'baz');
    is header_value($h, 'X-foo-bar'), 'baz', '-x_foo_bar becomes X-foo-bar';
}

# CVE-2026-120638: redirect() doesn't decode its URL
{
    my($status, $h) = $q->psgi_redirect('/&#47evil.example/');
    is $status, 302;
    is header_value($h, 'Location'), '/&#47evil.example/', 'entity in Location kept';

    $h = headers_of $q->psgi_redirect(-uri => 'http://example.com/?a=1&amp;b=2');
    is header_value($h, 'Location'), 'http://example.com/?a=1&amp;b=2', '&amp; kept verbatim';

    $h = headers_of $q->psgi_redirect(-uri => '/ok', -x_test => 'a&#13;&#10;b');
    is header_value($h, 'X-test'), 'a&#13;&#10;b', 'named extra redirect header kept verbatim';

    $h = headers_of $q->psgi_redirect(-uri => '/ok', -type => 'text/html');
    like header_value($h, 'Content-Type'), qr{^text/html}, '-type override in redirect';

    eval { $q->psgi_redirect(-uri => '/ok', -x_test => "a\r\nX-Evil: 1") };
    like $@, qr/contains a newline/, 'newline in named redirect extra dies';
}

# cookie and P3P array refs are checked per value
{
    eval { $q->psgi_header(-cookie => ["a=1", "b=2\r\nX-Evil: 1"]) };
    like $@, qr/contains a newline/, 'newline in a cookie arrayref dies';

    eval { $q->psgi_redirect(-uri => '/ok', -cookie => ["b=2\r\nX-Evil: 1"]) };
    like $@, qr/contains a newline/, 'newline in a redirect cookie arrayref dies';

    eval { $q->psgi_header(-p3p => ["CAO", "DSP\r\nX-Evil: 1"]) };
    like $@, qr/contains a newline/, 'newline in a P3P arrayref dies';

    my $h = headers_of $q->psgi_header(-p3p => [qw(CAO DSP)]);
    is header_value($h, 'P3P'), 'policyref="/w3c/p3p.xml", CP="CAO DSP"', 'P3P arrayref joined';
}

# -set-cookie is a cookie alias, as in CGI.pm
{
    my $h = headers_of $q->psgi_header('-set-cookie' => ['a=1', CGI::Cookie->new(-name => 'b', -value => 2)]);
    is_deeply [ header_value($h, 'Set-Cookie') ], [ 'a=1', 'b=2; path=/' ], '-set-cookie arrayref';
    ok header_value($h, 'Date'), 'Date header with cookies';

    $h = headers_of $q->psgi_header(-cookie => []);
    ok header_value($h, q{Date}), q{Date header with an empty cookie list, as in CGI.pm};

    $h = headers_of $q->psgi_redirect(-uri => q{/ok}, -cookie => []);
    ok header_value($h, q{Date}), q{Date header in redirect with an empty cookie list};

    $h = headers_of $q->psgi_redirect(-uri => '/ok', '-set-cookie' => 'a=1');
    is header_value($h, 'Set-Cookie'), 'a=1', '-set-cookie in redirect';
}

# -cookie together with -set-cookie behaves as in CGI.pm's header()
{
    my $h = headers_of $q->psgi_header(-cookie => 'a=1', '-set-cookie' => 'b=2');
    my $cgi = CGI->new({})->header(-cookie => 'a=1', '-set-cookie' => 'b=2');
    my @expected = $cgi =~ /^Set-Cookie: (.*?)\r$/mg;
    is_deeply [ header_value($h, 'Set-Cookie') ], \@expected, 'same cookies as CGI.pm';
}

# Location (and other named extras) from a URI object come out as strings, as on master
SKIP: {
    skip 'URI is not installed', 3 unless eval { require URI; 1 };

    my $h = headers_of $q->psgi_redirect(URI->new('/ok'));
    is ref(\$h->[1]), 'SCALAR', 'Location from a URI object is a plain string';
    is $h->[1], '/ok';

    $h = headers_of $q->psgi_header(-link => URI->new('/next'));
    is ref(\ header_value($h, 'Link')), 'SCALAR', 'extra header from a URI object is a plain string';
}

# CONTENT-TYPE wins over TYPE, as in CGI.pm
{
    for (1..5) {
        my $h = headers_of $q->psgi_header(-type => 'text/plain', -content_type => 'application/json');
        is header_value($h, 'Content-Type'), 'application/json', '-content_type wins over -type';
    }
}

# CVE-2026-120647: attachment filename is quote-escaped
{
    my $h = headers_of $q->psgi_header(-attachment => 'x.html"; filename*=evil');
    is header_value($h, 'Content-Disposition'), 'attachment; filename="x.html\"; filename*=evil"',
        'quote in attachment filename escaped';

    $h = headers_of $q->psgi_header(-attachment => 'a\\b');
    is header_value($h, 'Content-Disposition'), 'attachment; filename="a\\\\b"',
        'backslash in attachment filename escaped';
}

# newline in a header name dies
{
    eval { $q->psgi_header("-x_test\r\nX-Evil" => 'bar') };
    like $@, qr/contains a newline/, 'newline in a header name dies';
}

# charset is only defaulted for text/* types, as before
{
    my $h = headers_of $q->psgi_header(-type => 'application/json');
    is header_value($h, 'Content-Type'), 'application/json', 'no default charset for application/json';

    $h = headers_of $q->psgi_header(-type => 'application/json', -charset => 'utf-8');
    is header_value($h, 'Content-Type'), 'application/json; charset=utf-8', 'explicit charset';
}

done_testing;
