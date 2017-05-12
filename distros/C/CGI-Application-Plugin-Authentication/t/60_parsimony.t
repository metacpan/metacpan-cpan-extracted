#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t);

# Test script to test the following scenario:
# Once upon a time there was a perfectly good CGI::Application website with no need for authentication, sessions or cookies.
# Then one day the wicked step-boss came in and said "We need to have a login screen, or else I'll
# have to send you out into the big forest to fend for yourselves. Oh and if you change so much as a single 
# header on the existing web pages, I'll grind your bones for the shareholders' bread."
# Well what is a poor programmer to do? She can use CGI::Application::Plugin::Authentication
# but the unprotected pages never needed sessions or cookies so that must still be the case.
# However as long as this test passes, they all live happily ever after.

use Test::More;
eval "use TestAppParsimony";
plan skip_all => "CGI::Application::Plugin::Session etc required for this test" if $@;
plan tests => 6;

$ENV{CGI_APP_RETURN_ONLY} = 1;

sub response_like {
        my ($app, $header_re, $body_re, $comment) = @_;
        my $output = $app->run;
        my ($header, $body) = split /\r\n\r\n/m, $output;
        $header =~ s/\r\n/|/g;
        like($header, $header_re, "$comment (header match)");
        is($body,      $body_re,       "$comment (body match)");
}

{
        my $app = TestAppParsimony->new();
        $app->query(CGI->new({'rm' => 'unprotected'}));
        response_like(
                $app,
                qr{^Content-Type: text/html; charset=ISO-8859-1$},
                '<html><head/><body>This is public.</body></html>',
                'TestAppParsimony, unprotected'
        );
}

{
        my $app = TestAppParsimony->new();
        $app->query(CGI->new({'rm' => 'protected',auth_username=>'test', auth_password=>'123'}));
        response_like(
                $app,
                qr{^Set-Cookie: CGISESSID=\w{1,100}; path=/|Date: \w{3}, \d{1,2} \w{3} \d{4} \d{2}:\d{2}:\d{2} \d{3}|Content-Type: text/html; charset=ISO-8859-1$},
                '<html><head/><body>This is private.</body></html>',
                'TestAppParsimony, protected'
        );
}

{
        my $app = TestAppParsimony->new();
        $app->query(CGI->new({'rm' => 'unprotected'}));
        response_like(
                $app,
                qr{^Content-Type: text/html; charset=ISO-8859-1$},
                '<html><head/><body>This is public.</body></html>',
                'TestAppParsimony, unprotected reprise'
        );
}

