#!/usr/local/bin/perl -w

use strict;

use Test::More tests => 28;
use CGI::Util qw(escape unescape);
use POSIX qw(strftime);

#-----------------------------------------------------------------------------
# make sure module loaded
#-----------------------------------------------------------------------------

BEGIN {use_ok('CGI::Cookie');}
use CGI::PSGI;

my @test_cookie = (
		   'foo=123; bar=qwerty; baz=wibble; qux=a1',
		   'foo=123; bar=qwerty; baz=wibble;',
		   'foo=vixen; bar=cow; baz=bitch; qux=politician',
		   'foo=a%20phrase; bar=yes%2C%20a%20phrase; baz=%5Ewibble; qux=%27',
		   );

#-----------------------------------------------------------------------------
# Test fetch
#-----------------------------------------------------------------------------

# Breaks encapsulation to easily adapt to CGI.pm's cookie.t
my $get_cookie = sub {
    my $q = CGI::PSGI->new(shift);
    $q->cookie;
    %{ $q->{'.cookies'} || {} };
};

my $get_raw_cookie = sub {
    my $q = CGI::PSGI->new(shift);
    $q->raw_cookie('dummy');
    %{ $q->{'.raw_cookies'} || {} };
};

{
  # make sure there are no cookies in the environment
  delete $ENV{HTTP_COOKIE};
  delete $ENV{COOKIE};

  # now set a cookie in the environment and try again
  my $env = {};
  $env->{HTTP_COOKIE} = $test_cookie[2];
  my %result = $get_cookie->($env);
  ok(eq_set([keys %result], [qw(foo bar baz qux)]),
     "expected cookies extracted");

  is(ref($result{foo}), 'CGI::Cookie', 'Type of objects returned is correct');
  is($result{foo}->value, 'vixen',      "cookie foo is correct");
  is($result{bar}->value, 'cow',        "cookie bar is correct");
  is($result{baz}->value, 'bitch',      "cookie baz is correct");
  is($result{qux}->value, 'politician', "cookie qux is correct");

  # Delete that and make sure it goes away
  delete $env->{HTTP_COOKIE};
  %result = $get_cookie->($env);
  ok(keys %result == 0, "No cookies in environment, returns empty list");

  # try another cookie in the other environment variable thats supposed to work
  $env->{COOKIE} = $test_cookie[3];
  %result = $get_cookie->($env);
  ok(eq_set([keys %result], [qw(foo bar baz qux)]),
     "expected cookies extracted");

  is(ref($result{foo}), 'CGI::Cookie', 'Type of objects returned is correct');
  is($result{foo}->value, 'a phrase', "cookie foo is correct");
  is($result{bar}->value, 'yes, a phrase', "cookie bar is correct");
  is($result{baz}->value, '^wibble', "cookie baz is correct");
  is($result{qux}->value, "'", "cookie qux is correct");
}

#-----------------------------------------------------------------------------
# Test raw_fetch
#-----------------------------------------------------------------------------

{
  my $env = {};
  my %result = $get_raw_cookie->($env);
  ok(keys %result == 0, "No cookies in environment, returns empty list");

  # now set a cookie in the environment and try again
  $env->{HTTP_COOKIE} = $test_cookie[2];
  %result = $get_raw_cookie->($env);
  ok(eq_set([keys %result], [qw(foo bar baz qux)]),
     "expected cookies extracted");

  is(ref($result{foo}), '', 'Plain scalar returned');
  is($result{foo}, 'vixen',      "cookie foo is correct");
  is($result{bar}, 'cow',        "cookie bar is correct");
  is($result{baz}, 'bitch',      "cookie baz is correct");
  is($result{qux}, 'politician', "cookie qux is correct");

  # Delete that and make sure it goes away
  delete $env->{HTTP_COOKIE};
  %result = $get_raw_cookie->($env);
  ok(keys %result == 0, "No cookies in environment, returns empty list");

  # try another cookie in the other environment variable thats supposed to work
  $env->{COOKIE} = $test_cookie[3];
  %result = $get_raw_cookie->($env);
  ok(eq_set([keys %result], [qw(foo bar baz qux)]),
     "expected cookies extracted");

  is(ref($result{foo}), '', 'Plain scalar returned');
  is($result{foo}, 'a%20phrase', "cookie foo is correct");
  is($result{bar}, 'yes%2C%20a%20phrase', "cookie bar is correct");
  is($result{baz}, '%5Ewibble', "cookie baz is correct");
  is($result{qux}, '%27', "cookie qux is correct");
}
