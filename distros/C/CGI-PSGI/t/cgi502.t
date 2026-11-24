# CGI.pm 5.02 request-handling changes, seen through CGI::PSGI's env

use strict;
use warnings;
no warnings "once";

use Test::More;
use CGI::PSGI;

plan skip_all => "needs CGI.pm 5.02 (have $CGI::VERSION)" if $CGI::VERSION < 5.02;

{
    package MyInput;
    sub new { my($class, $s) = @_; bless { s => $s, pos => 0 }, $class }
    sub read {
        my $self = shift;
        my(undef, $len, $off) = @_;
        my $chunk = substr($self->{s}, $self->{pos}, $len);
        $self->{pos} += length $chunk;
        substr($_[0], $off || 0) = $chunk;
        return length $chunk;
    }
}

sub env {
    my(%e) = @_;
    my $body = delete $e{body};
    return {
        REQUEST_METHOD  => 'GET',
        QUERY_STRING    => '',
        SCRIPT_NAME     => '/app',
        SERVER_PROTOCOL => 'HTTP/1.0',
        SERVER_PORT     => 80,
        SERVER_NAME     => 'example.com',
        'psgi.input'    => MyInput->new(defined $body ? $body : ''),
        (defined $body ? (CONTENT_LENGTH => length $body) : ()),
        %e,
    };
}

# X-Forwarded-Host is ignored unless $CGI::TRUST_X_FORWARDED_HOST
{
    my $q = CGI::PSGI->new(env(HTTP_HOST => 'example.com', HTTP_X_FORWARDED_HOST => 'evil.example'));
    is $q->url, 'http://example.com/app', 'X-Forwarded-Host ignored';
    my(undef, $h) = $q->psgi_redirect;
    like $h->[1], qr{^http://example\.com/}, 'default redirect Location not taken from X-Forwarded-Host';

    local $CGI::TRUST_X_FORWARDED_HOST = 1;
    $q = CGI::PSGI->new(env(HTTP_HOST => 'example.com', HTTP_X_FORWARDED_HOST => 'proxy.example'));
    is $q->url, 'http://proxy.example/app', 'X-Forwarded-Host used when trusted';
}

# $CGI::POST_MAX is enforced on psgi.input, and reported through cgi_error
{
    local $CGI::POST_MAX = 10;
    my $q = CGI::PSGI->new(env(
        REQUEST_METHOD => 'POST',
        CONTENT_TYPE   => 'application/x-www-form-urlencoded',
        body           => 'a=' . ('x' x 100),
    ));
    like $q->cgi_error, qr/^413/, 'POST_MAX gives a 413 cgi_error';
}

# $CGI::MAX_PARAMS
{
    local $CGI::MAX_PARAMS = 3;
    my $q = CGI::PSGI->new(env(
        REQUEST_METHOD => 'POST',
        CONTENT_TYPE   => 'application/x-www-form-urlencoded',
        body           => join('&', map "p$_=1", 1..10),
    ));
    like $q->cgi_error, qr/^413/, 'MAX_PARAMS gives a 413 cgi_error';
}

# upload filenames are sanitised
{
    my $body = join "\r\n",
        '--XX',
        'Content-Disposition: form-data; name="file"; filename="../../etc/passwd"',
        'Content-Type: text/plain',
        '',
        'hello',
        '--XX--',
        '';
    my $q = CGI::PSGI->new(env(
        REQUEST_METHOD => 'POST',
        CONTENT_TYPE   => 'multipart/form-data; boundary=XX',
        body           => $body,
    ));
    is $q->param('file'), 'passwd', 'directory part removed from upload filename';
    my $fh = $q->upload('file');
    is scalar(<$fh>), 'hello', 'upload content read from psgi.input';
}

# client sent POSTDATA in the query string is ignored
{
    my $q = CGI::PSGI->new(env(QUERY_STRING => 'POSTDATA=evil&a=1'));
    is $q->param('a'), 1;
    ok !defined $q->param('POSTDATA'), 'POSTDATA from the query string ignored';
}

done_testing;
