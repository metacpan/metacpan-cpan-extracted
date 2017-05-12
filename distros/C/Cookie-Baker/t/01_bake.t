use strict;
use Test::More;
use Test::Time time => 1381154217;
use Cookie::Baker;

# Freeze time
my $now = time();

my @tests = (
    [ 'foo', 'val', 'foo=val'],
    [ 'foo', { value => 'val' }, 'foo=val'],
    [ 'foo', { value => 'foo bar baz' }, 'foo=foo%20bar%20baz'],
    [ 'foo', { value => 'val',expires => undef }, 'foo=val'],
    [ 'foo', { value => 'val',path => '/' }, 'foo=val; path=/'],
    [ 'foo', { value => 'val',path => '/', secure => 1, httponly => 0 }, 'foo=val; path=/; secure'],
    [ 'foo', { value => 'val',path => '/', secure => 0, httponly => 1 }, 'foo=val; path=/; HttpOnly'],
    [ 'foo', { value => 'val',expires => 'now' }, 'foo=val; expires=Mon, 07-Oct-2013 13:56:57 GMT'],
    [ 'foo', { value => 'val',expires => $now + 24*60*60 }, 'foo=val; expires=Tue, 08-Oct-2013 13:56:57 GMT'],
    [ 'foo', { value => 'val',expires => '1s' }, 'foo=val; expires=Mon, 07-Oct-2013 13:56:58 GMT'],
    [ 'foo', { value => 'val',expires => '+10' }, 'foo=val; expires=Mon, 07-Oct-2013 13:57:07 GMT'],
    [ 'foo', { value => 'val',expires => '+1m' }, 'foo=val; expires=Mon, 07-Oct-2013 13:57:57 GMT'],
    [ 'foo', { value => 'val',expires => '+1h' }, 'foo=val; expires=Mon, 07-Oct-2013 14:56:57 GMT'],
    [ 'foo', { value => 'val',expires => '+1d' }, 'foo=val; expires=Tue, 08-Oct-2013 13:56:57 GMT'],
    [ 'foo', { value => 'val',expires => '-1d' }, 'foo=val; expires=Sun, 06-Oct-2013 13:56:57 GMT'],
    [ 'foo', { value => 'val',expires => '+1M' }, 'foo=val; expires=Wed, 06-Nov-2013 13:56:57 GMT'],
    [ 'foo', { value => 'val',expires => '+1y' }, 'foo=val; expires=Tue, 07-Oct-2014 13:56:57 GMT'],
    [ 'foo', { value => 'val',expires => '0' }, 'foo=val; expires=Thu, 01-Jan-1970 00:00:00 GMT'],
    [ 'foo', { value => 'val',expires => '-1' }, 'foo=val; expires=Mon, 07-Oct-2013 13:56:56 GMT'],
    [ 'foo', { value => 'val',expires => 'foo' }, 'foo=val; expires=foo'],
);

for my $test (@tests) {
    is( bake_cookie($test->[0], $test->[1]), $test->[2] );
}

done_testing;
