#!/usr/bin/perl -w

use lib "/home/httpd/lib";
use lib "/home/httpd/lib.beta";

$::_test = 1;
use IO::File;
use IO::String;
use DBstorage::RDB;
use Test;

BEGIN {plan tests=>8;}

my($fh) = IO::File->new(">test.rdb.$$");
$fh->print(<<EOP);
foo	bar	boom
---	---	----
foo	bar	1
eek	am	2
454	343	3432
EOP
$fh->close();

my($dbh) = DBstorage::RDB->new();
my(%f);
$dbh->open("test.rdb.$$");
$dbh->read(\%f);
ok($f{'foo'}, "foo"); 
ok($f{'bar'}, "bar"); 
ok($f{'boom'}, "1"); 

unlink ("test.rdb.$$");


my($fh) = IO::File->new(">test.rdb.$$");
$fh->print(<<EOP);
foo	bar	boom
foo	bar	1
eek	am	2
454	343	3432
EOP
$fh->close();

my($dbh) = DBstorage::RDB->new();
my(%f);
$dbh->open("test.rdb.$$");
$dbh->read(\%f);
ok($f{'foo'}, "foo"); 
ok($f{'bar'}, "bar"); 
ok($f{'boom'}, "1"); 

unlink ("test.rdb.$$");


my (@field_list) = $dbh->fields();
ok(compare_arrays(\@field_list, ["foo", "bar", "boom"]));
$dbh->close();

ok($dbh->table_header(), <<EOP);
foo	bar	boom
---	---	----
EOP

$fh = IO::File->new(">test1.rdb.$$");
$fh->print(<<EOP);
foo	bar	boom
---	---	----
foo	bar	1
eek	am	2
454	343	3432
EOP
$fh->close();

$fh = IO::File->new(">test2.rdb.$$");
$fh->print(<<EOP);
foo	bar	boom
---	---	----
foo	bar	1
eek	am	2
454	343	3432
EOP
$fh->close();

`ci -u -t-'test-message' test1.rdb.$$`;

#$dbh->commit("test1.rdb.$$", "test2.rdb.$$");

#ok(-w "test1.rdb.$$.bak", 1);

unlink ("test1.rdb.$$");
unlink ("test1.rdb.$$,v");
unlink ("test2.rdb.$$");


           sub compare_arrays {
               my ($first, $second) = @_;
               no warnings;  # silence spurious -w undef complaints
               return 0 unless @$first == @$second;
               for (my $i = 0; $i < @$first; $i++) {
                   return 0 if $first->[$i] ne $second->[$i];
               }
               return 1;
           }
