#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
# This kludge is necessary to avoid failing due to circular dependencies
# with Catalyst-Runtime. Not ideal, but until we remove CDR from
# Catalyst-Runtime prereqs, this is necessary to avoid Catalyst-Runtime build
# failing.
BEGIN {
    plan skip_all => 'Catalyst::Runtime required'
        unless eval { require Catalyst };
    plan skip_all => 'Test requires Catalyst::Runtime >= 5.90030' unless $Catalyst::VERSION >= 5.90030;
}

use_ok('TestApp');

my $dispatcher = TestApp->dispatcher;

#
#   Regex Action
#
my $regex_action = $dispatcher->get_action_by_path(
                     '/action/regexp/one'
                   );

ok(!defined($dispatcher->uri_for_action($regex_action)),
   "Regex action without captures returns undef");

ok(!defined($dispatcher->uri_for_action($regex_action, [ 1, 2, 3 ])),
   "Regex action with too many captures returns undef");

is($dispatcher->uri_for_action($regex_action, [ 'foo', 123 ]),
   "/action/regexp/foo/123",
   "Regex action interpolates captures correctly");

my $regex_action_bs = $dispatcher->get_action_by_path(
                     '/action/regexp/one_backslashes'
                   );

ok(!defined($dispatcher->uri_for_action($regex_action_bs)),
   "Regex action without captures returns undef");

ok(!defined($dispatcher->uri_for_action($regex_action_bs, [ 1, 2, 3 ])),
   "Regex action with too many captures returns undef");

is($dispatcher->uri_for_action($regex_action_bs, [ 'foo', 123 ]),
   "/action/regexp/foo/123.html",
   "Regex action interpolates captures correctly");

#
#   Tests with Context
#
my $request = Catalyst::Request->new( {
                _log => Catalyst::Log->new,
                base => URI->new('http://127.0.0.1/foo')
              } );

my $context = TestApp->new( {
                request => $request,
                namespace => 'yada',
              } );

is($context->uri_for($regex_action, [ 'foo', 123 ], qw/bar baz/, { q => 1 }),
   "http://127.0.0.1/foo/action/regexp/foo/123/bar/baz?q=1",
   "uri_for correct for regex with captures, args and query");

done_testing;

