#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->subdir('lib')->stringify;

use HTTP::Request::Common;
use Catalyst::Test 'TestApp';
use Data::Dumper;

# Each element is a hashref, with the following key-value pairs:
#   request_path: The URI of the request.
#   expected: The expected return value of $c->language_switch_options().
my @tests = (
  {
    request_path => '/en/foo/bar?baz=42',
    expected => {
      en => {
        name => 'English',
        uri => str('http://localhost/en/foo/bar?baz=42'),
      },
      de => {
        name => 'German',
        uri => str('http://localhost/de/foo/bar?baz=42'),
      },
      fr => {
        name => 'French',
        uri => str('http://localhost/fr/foo/bar?baz=42'),
      },
      it => {
        name => 'Italian',
        uri => str('http://localhost/it/foo/bar?baz=42'),
      },
    },
  },
  {
    request_path => '/de/foo/bar',
    expected => {
      en => {
        name => 'Englisch',
        uri => str('http://localhost/en/foo/bar'),
      },
      de => {
        name => 'Deutsch',
        uri => str('http://localhost/de/foo/bar'),
      },
      fr => {
        name => 'Franzäsisch',
        uri => str('http://localhost/fr/foo/bar'),
      },
      it => {
        name => 'Italienisch',
        uri => str('http://localhost/it/foo/bar'),
      },
    },
  },
);

{
  foreach my $test (@tests) {
    my $test_description =
      Data::Dumper->new([
        +{
          map {
            ( $_ => $test->{$_} )
          } qw(request_path)
        }
      ])->Terse(1)->Indent(0)->Quotekeys(0)->Dump;

    my ($response, $c) = ctx_request(GET $test->{request_path});

    ok(
      $response->is_success,
      "The request was successful ($test_description)"
    );

    lives_and {
      cmp_deeply(
        $c->language_switch_options,
        $test->{expected},
      );
    } "\$c->language_switch_options() returns the expected data structure";
  }
}

done_testing;
