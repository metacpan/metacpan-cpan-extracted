#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Path;
use Time::HiRes qw(time sleep);

plan skip_all => "needs Catalyst::Plugin::Cache for testing: $@"
    if not eval "use Catalyst::Plugin::Cache; 1";

plan skip_all => 'Cannot run this test on Windows' # XXX still true?
    if $^O =~ /Win32/;

plan tests => 7;

use Catalyst::Test 'TestApp';

TestApp->config->{'Plugin::PageCache'}->{busy_lock} = 5;

ok( request('http://host1/cache/set_count/0', 'request ok' ) );
# Request a slow page once, to cache it
ok( my $res = request('http://localhost/cache/busy'), 'request ok' );
is( $res->content, 1, 'count is 1' );

sleep 1; # delay so cached page will have expired
my $cache_time = time + 1;
1 while time < $cache_time; # spin till clock ticks to make test more robust

# Fork, parent requests slow page.  After parent requests, child
# requests, and gets cached page while parent is rebuilding cache
if ( my $pid = fork ) {
    # parent
    my $start = time();
    ok( $res = request('http://localhost/cache/busy'), 'parent request ok' );
    cmp_ok( time() - $start, '>=', 1, 'slow parent response ok' );
    is( $res->content, 2, 'parent generated new response' );
    
    # Get status from child, since it can't print 'ok' messages without
    # confusing Test::More
    wait;
    is( $? >> 8, 0, "fast child response ($?)" );
}
else {
    # child
    sleep 1; # delay to ensure parent makes request first
    # but not long enough for the parent to have finished
    my $start = time();
    $res = request('http://localhost/cache/busy');
    my $dur = time() - $start;

    my $errors = 0;

    my $content = $res->content;
    if ($content ne '1') {
        warn "Child didn't get cached response ($content)\n";
        ++$errors;
    }
    if ($dur >= 1) {
        warn "Child got response slowly ($dur)\n";
        ++$errors;
    }

    exit $errors;
}
