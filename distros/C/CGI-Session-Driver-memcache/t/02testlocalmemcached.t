# test against Memcached running locally or at $ENV{'MEMCACHED_HOST'}
use Test::More;
use lib '..';
use strict;
use warnings;
use Data::Dumper;
#use Scalar::Util;

#use_ok('CGI');
#use_ok('CGI::Session');

my $memdhost = $ENV{'MEMCACHED_HOST'} || 'localhost';

eval("use Cache::Memcached;");
if ($@) {plan('skip_all', "No Cache::Memcached installed");}
plan('tests', 6);

my $memd = Cache::Memcached->new({
  'servers' => [ "$memdhost:11211" ], 'debug' => 0,
});
if (!$memd) {die("Failed to instantiate memcached Server Connection to '$memdhost'");}
ok($memd, "Got Memcached connection to '$memdhost'");
isa_ok($memd, 'Cache::Memcached');

my $s = $memd->stats();
ok($s, "Got stats (to see server is alive)"); # .Dumper($s)
ok(ref($s) eq 'HASH', "Stats Returned in HASH");
# 
my $key = "from.$$";
my $val1 = "Hello $$";
my $ok = $memd->set($key, "Hello $$");
ok($ok, "Sent k-v successfully ('$key', '$val1')");
# 
my $val = $memd->get($key);
ok($val eq $val1, "Got identical value back ('$val') for key '$key'");
