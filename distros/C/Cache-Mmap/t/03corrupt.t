# Test of behaviour wrt corrupt cache files
# $Id: 03corrupt.t,v 1.7 2004/03/15 16:35:37 pmh Exp $

# This test is aware of some of the structure of the cache files
# Be careful when changing things

use IO::File;
use Test::More tests => 26;
use strict;
BEGIN{ use_ok('Cache::Mmap'); }

BEGIN{
  if($]>=5.008){
    require 'open.pm';
    open::import(open => OUT => ':raw');
  }
}

chdir 't' if -d 't';
my $fname='corrupt.cmm';

# Create a new cache file
ok(my $cache=newcache(),'creating cache file 1');

my $pagesize=$cache->pagesize;
my $bucketsize=$cache->bucketsize;
my $headsize=40;
my $bheadsize=40;
my $eheadsize=40;
is($cache->buckets,1,'only one bucket');

# Make it seem very full
substr($cache->{_mmap},$pagesize,4)='huge';

# Attempt to read something
eval{ $cache->read('abc'); };
ok($@=~/Zero-sized/,'zero-sized error');

# Start again
ok($cache=newcache(),'creating cache file 2');

# Add a normal entry
ok($cache->write('abc','def'),'adding entry');

# Check it's OK
is($cache->read('abc'),'def','checking entry');

# Make it seem very long
substr($cache->{_mmap},$pagesize,4)=pack 'l',1000;
substr($cache->{_mmap},$pagesize+$bheadsize,4)=pack 'l',100;

# Attempt to read something
eval{ $cache->read('abs'); };
ok($@=~/Super-sized/,'super-sized error');

# Start a new cache, with a low expiry date
ok($cache=newcache(expiry => 5),'creating cache file 3');

# Add an entry which will expire
ok($cache->write('old','dlo'),'adding old entry');
sleep 6;

# Add an entry which will replace the first entry
ok($cache->write('new','wen'),'adding new entry');

# Check we've got what we expect
is($cache->read('new'),'wen','new entry still present');
is($cache->read('old'),undef,'old entry expired');

# Start a new cache file
ok($cache=newcache(),'creating cache file 4');
undef $cache;

# Make sure it's OK when we open it again
ok($cache=eval{ Cache::Mmap->new($fname); },'reopened cache file 4');


# Try accessing a file with the wrong magic number
ok(unlink($fname),'delete old file');
undef $cache;
sleep 2;

ok(my $fh=IO::File->new($fname,'>'),'creating broken file 1')
  or print "# Can't open $fname: $!\n";
my $head=pack "l$headsize",12345;
ok(syswrite($fh,$head,length $head),'writing broken header');
ok(close $fh,'closing broken file');
if(my $cache=eval{ Cache::Mmap->new($fname); }){
  print "# $cache\n";
}else{
  print "# $@";
}
ok($@=~/not a Cache::Mmap file/,"magic number check");

# Try accessing a file with a different file format
ok(unlink($fname),'delete old file');
undef $cache;
sleep 2;

ok($fh=IO::File->new($fname,'>'),'creating broken file 2')
  or print "# Can't open $fname: $!\n";
$head=pack "l$headsize",0x15ACACE,1,2,3,4,5,6,7,8,9;
ok(syswrite($fh,$head,length $head),'writing broken header');
ok(close $fh,'closing broken file');
if(my $cache=eval{ Cache::Mmap->new($fname); }){
  print "# $cache\n";
}else{
  print "# $@";
}
ok($@=~/only supports v/,"file format version check");







unlink $fname;
ok(1,'final test');

sub newcache{
  unlink $fname;

  my $cache=Cache::Mmap->new($fname,{
    strings => 1,
    pagesize => 100,
    bucketsize => 100,
    buckets => 1,
    @_,
  });
}

