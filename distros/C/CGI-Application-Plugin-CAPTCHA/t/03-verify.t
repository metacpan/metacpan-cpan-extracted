#!/usr/bin/env perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { use Test::WWW::Mechanize };
    plan skip_all => "Test::WWW::Mechanize required for tests" if $@;
}

plan tests => 7;

# Bring in testing hierarchy
use lib './t';

# Set up testing webapp
use TestApp;
$ENV{CGI_APP_RETURN_ONLY} = 1;

# Set up testing web server
use CAPCServer;
use constant PORT => 13432;

my $server = CAPCServer->new(PORT);
my $pid = $server->background;
ok($pid, 'HTTP Server started') or die "Can't start the server";

sub cleanup { kill(9, $pid) };
$SIG{__DIE__} = \&cleanup;

CREATE_TESTING:
{
    # Create our mech object
    my $mech = Test::WWW::Mechanize->new( cookie_jar => {} );

    # Force the base app to render some output (something it should NOT normally do!).
    # Capture the result.
    $mech->get_ok('http://localhost:' . PORT . '/', "Got CAPTCHA successfully");

    # Get the cookie we should have been fed
    my $jar = $mech->cookie_jar;
    isa_ok($jar, "HTTP::Cookies");

    # Make sure we got a cryptographic hash in a cookie
    my $cookie = $jar->as_string;
    my ($hash) = $cookie =~ /hash=(.*?);/;
    isnt($hash, "", "Received cryptographic hash in cookie");

    # Make sure our cookie contains the CAPTCHA value ABC123
    my $secret = 'vbCrfzMCi45TD7Uz4C6fjWvX6us';
    my $check  = Digest::SHA1::sha1_base64(join("\0", $secret, 'ABC123'));
    #my $salt = substr($hash, 0, 2);
    #ok(crypt("ABC123", $salt) eq $hash, "Hash contains CAPTCHA value ABC123");
    ok( $check eq $hash, "Hash contains CAPTCHA value ABC123");

    # Make sure captcha_verify() actually verifies!
    my $app = TestApp2->new();
    ok($app->captcha_verify($hash, "ABC123"), "CAPTCHA successfully verified");

    # Make sure captcha_verify() rejects an invalid verification string
    cmp_ok($app->captcha_verify($hash, "invalid"), "==", 0, "CAPTCHA not verified");
}

CLEANUP:
{
    cleanup();
}

