# Test of entries() method
# $Id: 02entries.t,v 1.3 2003/10/30 18:45:59 pmh Exp $

use Test::More tests => 6;
use strict;
BEGIN{ use_ok('Cache::Mmap'); }

# Prepare the ground
chdir 't' if -d 't';
my $fname='entries.cmm';
unlink $fname;

ok(my $cache=Cache::Mmap->new($fname,{strings => 1}),'creating cache file');

ok(eq_array([$cache->entries],[]),'cache should be empty');

for(1..5){
  $cache->write($_,$_*$_);
}

ok(eq_set([$cache->entries],[1..5]),'simple entries(): '.join ' ',$cache->entries);

my @entries=sort { $a->{key} cmp $b->{key} } $cache->entries(1);
foreach(@entries){
  delete $_->{'time'}; # We can't guarantee the time we think it went in
}
my @expect=map +{ key => $_, dirty => 0, },1..5;
ok(eq_array(\@entries,\@expect),'complex entries()');

@entries=sort { $a->{key} cmp $b->{key} } $cache->entries(2);
foreach(@entries){
  delete $_->{'time'}; # We can't guarantee the time we think it went in
}
foreach(@expect){
  $_->{value}=$_->{key} * $_->{key};
}
ok(eq_array(\@entries,\@expect), 'complex entries() with values');

unlink $fname;


