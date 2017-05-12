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
#   args: An arraryref, the args for C<< $c->uri_for_in_language() >>.
#   expected_uri: String, the expected URI.
my @tests = (
  {
    args => [ en => '/' ],
    expected_uri => 'http://localhost/en/',
  },

  {
    args => [ en => '/foo/bar' ],
    expected_uri => 'http://localhost/en/foo/bar',
  },
  {
    args => [ EN => '/foo/bar' ],
    expected_uri => 'http://localhost/en/foo/bar',
  },

  {
    args => [ de => '/foo/bar' ],
    expected_uri => 'http://localhost/de/foo/bar',
  },

  {
    args => [ de => '/language_independent_stuff' ],
    expected_uri => 'http://localhost/language_independent_stuff',
    todo => '$c->uri_for_in_language() currently does not work for '
      . 'language independent paths.',
  },

  {
    args => [ en => '/foo/bar%2Fbaz' ],
    expected_uri => 'http://localhost/en/foo/bar%2Fbaz',
  },
);

{
  my ($response, $c) = ctx_request(GET '/en');

  ok(
    $response->is_success,
    "The request was successful"
  );

  foreach my $test (@tests) {
    my $test_description =
      Data::Dumper->new([
        +{
          map {
            ( $_ => $test->{$_} )
          } qw(args)
        }
      ])->Terse(1)->Indent(0)->Quotekeys(0)->Dump;

    local $TODO = $test->{todo};

    my $uri_for_result_before = $c->uri_for(@{ $test->{args} }[ 1 .. $#{ $test->{args} } ]);

    is(
      $c->uri_for_in_language(@{ $test->{args} }),
      $test->{expected_uri},
      "\$c->uri_for_in_language() returns the expected URI ($test_description)"
    );

    is(
      $c->uri_for(@{ $test->{args} }[ 1 .. $#{ $test->{args} } ]),
      $uri_for_result_before,
      "\$c->uri_for() returns the same URI as before calling "
        . "\$c->uri_for_in_language() ($test_description)"
    );
  }
}

done_testing;
