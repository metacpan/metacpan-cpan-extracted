#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::API::Docker::Mock;

# Regression coverage for the test harness itself (karr k109), not for
# lib/: Test::API::Docker::Mock's fallback route matching used to
# interpolate a route key straight into a regex (`m{^$route_path$}` in
# _mock_docker), so a key containing a regex metacharacter was read as a
# pattern rather than as the literal path it looks like. `.` is the case
# that bites here: it matches any single character, so a route meant for one
# exact path silently also matched a different path that happened to differ
# only at the position the dot sat. Fixed with \Q...\E so the fallback tier
# is literal matching, tolerant only of whitespace between method and path
# -- which is what every route key in this suite, bar the one dynamic
# pattern in t/streaming_methods.t, was written as though it already were.
#
# The fallback tier only runs once the request path fails an EXACT string
# match against a route key (the `exists $routes{$key}` fast path in
# _mock_docker), so a route with a metacharacter has to be probed with a
# path that is close but not identical to reach it -- an exact hit never
# touches the regex at all.

check_live_access();

subtest 'a route key with a regex metacharacter is matched literally, not as a pattern' => sub {
  plan skip_all => 'the mock route table is bypassed in live mode' if is_live();

  # sha256:deadbeef.dead and sha256:deadbeefXdead differ only at the dot's
  # position and are otherwise the same length. Unescaped,
  # m{^sha256:deadbeef.dead$} reads the dot as "any character" and matches
  # the second string too, even though only the first was ever registered.
  my $docker = test_docker(
    'GET /images/sha256:deadbeef.dead/json' => { Id => 'the-dotted-one' },
  );

  my $exact = $docker->images->inspect('sha256:deadbeef.dead');
  is $exact->id, 'the-dotted-one',
    'the literal path the route key names still matches -- this one is an '
    . 'exact hash hit and never reaches the regex fallback at all';

  my $err = do {
    local $@;
    eval { $docker->images->inspect('sha256:deadbeefXdead') };
    $@;
  };
  like $err, qr/No mock route for/,
    'a path that only accidentally resembles the route key -- same length, '
    . 'differing at exactly the position the "." sat -- is refused rather '
    . 'than matched. On the old, unescaped fallback this returned '
    . 'the-dotted-one instead of croaking: a route for one image answering '
    . 'for a different one';
};

done_testing;
