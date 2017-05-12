# Simple test of cache with default parameters
# $Id: 01simple.t,v 1.2 2003/06/13 16:22:22 pmh Exp $

use Test::More tests => 46;
BEGIN{ use_ok('Cache::Mmap'); }
use strict;

# Prepare the ground
chdir 't' if -d 't';
my $fname='test.cmm';
unlink $fname;

# Check defaults are OK
ok(my $cache=Cache::Mmap->new($fname,{}),'creating cache file');
foreach(
  [buckets => 13],
  [bucketsize => 1024],
  [pagesize => 1024],
  [strings => 0],
  [expiry => 0],
  [cachenegative => 0],
  [writethrough => 1],
){
  my($key,$val)=@$_;
  is($cache->$key(),$val,"default $key");
}

# There shouldn't be anything in the file
is($cache->read('some random key'),undef,'cache is empty');

# Store some stuff in the file
my %data;
for(1..10){
  my $datum=[map chr(65+$_) x $_,0..$_];
  $data{$_}=$datum;
  $cache->write($_,$datum);
}
for(1..10){
  ok(eq_array(scalar $cache->read($_),$data{$_}),"read $_: @{$data{$_}}");
}

# Overwite some entries
for(3,5,7){
  my $datum={map +($_ => 'z' x $_),1..$_};
  $data{$_}=$datum;
  $cache->write($_,$datum);
}
for(1,2,4,6,8,9,10){
  ok(eq_array(scalar $cache->read($_),$data{$_}),"overwrite $_: @{$data{$_}}");
}
for(3,5,7){
  ok(eq_hash(scalar $cache->read($_),$data{$_}),"overwrite $_: @{[%{$data{$_}}]}");
}

# Delete some entries
for(3,6,9){
  my($found,$datum)=$cache->delete($_);
  ok($found,"delete $_");
  ok($_==3 ? eq_hash($datum,$data{$_}) : eq_array($datum,$data{$_}),"delete data $_");
}

# Check that everything else is still OK
for(1..10){
  my($found,$datum)=$cache->read($_);
  if(not $_%3){
    ok(!$found,"deleted $_");
  }elsif(!$found){
    fail("deleted $_");
  }elsif($_==5 || $_==7){
    ok(eq_hash($datum,$data{$_}),"deleted $_");
  }else{
    ok(eq_array($datum,$data{$_}),"deleted $_");
  }
}

unlink $fname;
