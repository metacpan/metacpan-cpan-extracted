#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->subdir('lib')->stringify;

use HTTP::Request::Common;
use Catalyst::Test 'TestApp';
use Data::Dumper;

# Each element is a hashref, with the following key-value pairs:
#   request_path: The URI of the request.
#   new_language: The parameter to $c->switch_language().
#   expected: A hashref that contains the expected values after $c->switch_language().
#     It contains following key-value pairs:
#       language: The expected single value of $c->languages.
#       req: The expected value of some $c->req methods. A hashref with the
#         following key-value pairs:
#           uri: The expected value of $c->req->uri.
#           base: The expected value of $c->req->base.
#           path: The expected value of $c->req->path.
my @tests = (
  {
    request_path => '/en/foo/bar',
    new_language => 'de',
    expected => {
      language => 'de',
      req => {
        uri => 'http://localhost/de/foo/bar',
        base => 'http://localhost/de/',
        path => 'foo/bar',
      },
    },
  },
  {
    request_path => '/en/foo/bar',
    new_language => 'DE',
    expected => {
      language => 'de',
      req => {
        uri => 'http://localhost/de/foo/bar',
        base => 'http://localhost/de/',
        path => 'foo/bar',
      },
    },
  },

  {
    request_path => '/language_independent_stuff',
    new_language => 'de',
    expected => {
      language => 'de',
      req => {
        uri => 'http://localhost/language_independent_stuff',
        base => 'http://localhost/',
        path => 'language_independent_stuff',
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
          } qw(request_path new_language)
        }
      ])->Terse(1)->Indent(0)->Quotekeys(0)->Dump;

    my ($response, $c) = ctx_request(GET $test->{request_path});

    ok(
      $response->is_success,
      "The request was successful ($test_description)"
    );

    lives_ok {
      $c->switch_language($test->{new_language});
    } "\c->switch_language() does not die ($test_description)";

    cmp_deeply(
      $c->languages,
      [ $test->{expected}->{language} ],
      "\$c->languages is set to the expected value ($test_description)"
    );

    is(
      $c->req->uri,
      $test->{expected}->{req}->{uri},
      "\$c->req->uri is set to the expected value ($test_description)"
    );

    isa_ok($c->req->uri, 'URI', "\$c->req->uri ($test_description)");

    is(
      $c->req->base,
      $test->{expected}->{req}->{base},
      "\$c->req->base is set to the expected value ($test_description)"
    );

    isa_ok($c->req->base, 'URI', "\$c->req->base ($test_description)");

    is(
      $c->req->path,
      $test->{expected}->{req}->{path},
      "\$c->req->path is set to the expected value ($test_description)"
    );
  }
}

done_testing;
