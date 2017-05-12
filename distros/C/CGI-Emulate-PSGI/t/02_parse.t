use strict;
use Test::More;
use CGI::Parse::PSGI qw(parse_cgi_output);

{
    my $output = <<CGI;
Status: 302
Content-Type: text/html
X-Foo: bar
Location: http://localhost/

This is the body!
CGI

    my($r, $h) = _parse($output);
    is $r->[0], 302;

    is $h->content_length, 18;
    is $h->content_type, 'text/html';
    is $h->header('Location'), 'http://localhost/';

    is_deeply $r->[2], [ "This is the body!\n" ];
}

{
    # rfc3875 6.2.3
    my $output = <<CGI;
Location: http://google.com/

CGI
    my($r, $h) = _parse($output);
    is $r->[0], 302;
    is $h->header('Location'), 'http://google.com/';
}

{
    # rfc3875 6.2.4
    my $output = <<CGI;
Status: 301
Location: http://google.com/
Content-Type: text/html

Redirected
CGI
    my($r, $h) = _parse($output);
    is $r->[0], 301;
    is $h->header('Location'), 'http://google.com/';
    is $h->content_type, 'text/html';
    is_deeply $r->[2], [ "Redirected\n" ];
}

{
    # Check that status header wins when present in addition to status line 200
    my $output = <<CGI;
HTTP/1.0 200 OK
Status: 404
Content-Type: text/plain

Not found
CGI

    my($r, $h) = _parse($output);
    is $r->[0], 404;
}

{
    # Check status header (!=200) still wins when status line present, and not 200
    my $output = <<CGI;
HTTP/1.0 400 Bad Request
Status: 404
Content-Type: text/plain

Not found
CGI

    my($r, $h) = _parse($output);
    is $r->[0], 404;
}

{
    # Check status header (==200) still wins when status line present, and not 200
    my $output = <<CGI;
HTTP/1.0 400 Bad Request
Status: 200
Content-Type: text/plain

OK
CGI

    my($r, $h) = _parse($output);
    is $r->[0], 200;
}

{
    # Check status line is observed when status header is absent
    my $output = <<CGI;
HTTP/1.0 400 Bad Request
Content-Type: text/plain

Invalid parameters
CGI

    my($r, $h) = _parse($output);
    is $r->[0], 400;
}

{
    # Check option hash is ignored when unimplemented -
    # i.e. status line is not observed even when status header is absent
    my $output = <<CGI;
HTTP/1.0 400 Bad Request
Content-Type: text/plain

Invalid parameters
CGI

    my($r, $h) = _parse($output, {ignore_status_line => 0});
    is $r->[0], 400;

    ($r, $h) = _parse($output, {ignore_status_line => 1});
    is $r->[0], 200;
}

{
    # Check option hash is ignored when unimplemented -
    # i.e. default status is 200 when status header is absent
    my $output = <<CGI;
Content-Type: text/plain

Ok
CGI

    my($r, $h) = _parse($output, {ignore_status_line => 0});
    is $r->[0], 200;

    ($r, $h) = _parse($output, {ignore_status_line => 1});
    is $r->[0], 200;
}

done_testing;

sub _parse {
    my $output = shift;
    my $r = parse_cgi_output(\$output, @_);

    my $h = HTTP::Headers->new;
    while (my($k, $v) = splice @{$r->[1]}, 0, 2) {
        $h->header($k, $v);
    }
    return $r, $h;
}
