#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Plack::Util;
use CGI::Parse::PSGI::Streaming;

sub _parse {
    my $output = shift;
    my $r;
    my $responder = sub {
        my ($response) = @_;
        $r = $response;
        return Plack::Util::inline_object(
            write => sub { push @{$r->[2]}, shift },
            close => sub {},
        );
    };
    my $stdout = CGI::Parse::PSGI::Streaming::parse_cgi_output_streaming_fh(
        $responder,
    );
    print {$stdout} $output;

    my $h = HTTP::Headers->new;
    while (my($k, $v) = splice @{$r->[1]}, 0, 2) {
        $h->header($k, $v);
    }
    return $r, $h;
}

subtest 'redirect' => sub {
    my $output = <<CGI;
Status: 302
Content-Type: text/html
X-Foo: bar
Location: http://localhost/

This is the body!
CGI

    my($r, $h) = _parse($output);
    is $r->[0], 302,
        'the status should be 302';

    is $h->content_type, 'text/html',
        'the content should be marked as HTML';
    is $h->header('Location'), 'http://localhost/',
        'the location header should be set';

    is_deeply $r->[2], [ "This is the body!\n" ],
        'the body should be there';
};

subtest 'rfc3875 6.2.3' => sub {
    my $output = <<CGI;
Location: http://google.com/

CGI
    my($r, $h) = _parse($output);
    is $r->[0], 302,
        'the status should be 302';
    is $h->header('Location'), 'http://google.com/',
        'the location header should be set';
};

subtest 'rfc3875 6.2.4' => sub {
    my $output = <<CGI;
Status: 301
Location: http://google.com/
Content-Type: text/html

Redirected
CGI
    my($r, $h) = _parse($output);
    is $r->[0], 301,
        'the status should be 301';
    is $h->header('Location'), 'http://google.com/',
        'the location header should be set';
    is $h->content_type, 'text/html',
        'the content should be marked as HTML';
    is_deeply $r->[2], [ "Redirected\n" ],
        'the body should be there';
};

done_testing;
