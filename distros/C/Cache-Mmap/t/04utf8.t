# Test that UTF8 values are read/written correctly
# $Id: 04utf8.t,v 1.3 2003/06/17 18:10:55 pmh Exp $

use Test::More;
BEGIN{
  # Should use C<plan> here, but ancient Test::More doesn't like it
  if($^V){
    Test::More->import(tests => 13);
  }else{
    Test::More->import(skip_all => 'Test irrelevant without utf8 support');
  }
  use_ok('Cache::Mmap');
}
use strict;

chdir 't' if -d 't';
my $fname='utf8.cmm';
unlink $fname;


ok(my $cache=Cache::Mmap->new($fname,{buckets => 1, strings => 1}),
  'creating cache file');

ok($cache->write('abc','\x{1234}\x{4321}'), 'writing plain value');

is($cache->read('abc'),'\x{1234}\x{4321}', 'reading plain value');

ok($cache->write('def',"\x{5678}\x{8765}"), 'writing utf8 value');

ok(scalar $cache->read('def') eq "\x{5678}\x{8765}", 'reading utf8 value');

ok($cache->write('ghi','\x{9abc}\x{cba9}'), 'writing post-utf8 plain value');

is($cache->read('ghi'),'\x{9abc}\x{cba9}', 'reading post-utf8 plain value');

is($cache->read('abc'),'\x{1234}\x{4321}', 'reading pre-utf8 plain value');

ok($cache->write("\x{1234}",'1234'), 'writing utf8 key');

is($cache->read("\x{1234}"),'1234', 'reading utf8 key');

ok($cache->write("\xff",'ffff'), 'writing 8 bit key');

is($cache->read("\xff"),'ffff', 'reading 8 bit key');



unlink $fname;
