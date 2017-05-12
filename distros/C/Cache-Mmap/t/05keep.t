# Test of CMM_keep_expired special values
# $Id: 05keep.t,v 1.1 2003/10/30 18:46:45 pmh Exp $

use Test::More tests => 9;
use strict;
BEGIN{ use_ok('Cache::Mmap',qw(CMM_keep_expired CMM_keep_expired_refresh)); }

# Prepare the ground
chdir 't' if -d 't';
my $fname='keep.cmm';
unlink $fname;

my($found,$val);
ok(my $cache=Cache::Mmap->new($fname,{
  strings => 1,
  expiry => 5, # Needs to be long enough to keep slow machines happy
  read => sub{
    return ($found,$val);
  },
}),'creating cache file');

$cache->write(keep => 'peek');
$cache->write(lose => 'sole');

is($cache->read('keep'),'peek','keep => peek');
is($cache->read('lose'),'sole','lose => sole');

print "# sleep 6\n";
sleep 6; # Let things expire
is($cache->read('lose'),undef,'lost lose');
($found,$val)=(CMM_keep_expired_refresh,'banana');
is($cache->read('keep'),'peek','refresh');
is($cache->read('keep'),'peek','stays refreshed');

print "# sleep 6\n";
sleep 6; # Expire again
$found=CMM_keep_expired;
is($cache->read('keep'),'peek','still here');
undef $found;
is($cache->read('keep'),undef,'really expired');


unlink $fname;


