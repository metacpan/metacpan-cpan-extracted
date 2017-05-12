#!perl -T

use strict;
use warnings;
use Time::HiRes;
use Test::More tests => 46;

BEGIN {
  use_ok ('CDB::TinyCDB::Wrapper') || BAIL_OUT ("Can't load module code");
}

-f "t/test.cdb" && unlink "t/test.cdb";

#diag ("Testing CDB::TinyCDB::Wrapper $CDB::TinyCDB::Wrapper::VERSION, Perl $], $^X");

my $db;

ok ($db = CDB::TinyCDB::Wrapper->new ("t/test.cdb"), "Create t/test/cdb");
isa_ok ($db, "CDB::TinyCDB::Wrapper", "Check type of object");
is ($db->get ("foo"), undef, "Try to get a non-existent value");
ok ($db->set ("foo", 1), "Try to set a value");
is_deeply ([$db->each], ['foo', 1], "Get back our lone key/value pair");
is ($db->each, (), "We should be done iterating");
is (undef $db, undef, "Test the old close-on-last-reference interface");

ok ($db = CDB::TinyCDB::Wrapper->new ("t/test.cdb"), "Re-open t/test/cdb");
is ($db->get ("foo"), 1, "Try to get the value we just set");
ok ($db->del ("foo"), "Try to delete a value");
is ($db->get ("foo"), undef, "Try to get a non-existent value");
ok ($db->close, "Closing the file to rewrite it");

ok ($db = CDB::TinyCDB::Wrapper->new ("t/test.cdb"), "Re-open t/test/cdb");
is ($db->get ("foo"), undef, "Try to get a non-existent value");
ok ($db->set ("foo", 1), "Try to set a value");
ok ($db->set ("bar", 2), "Try to set a value");
ok ($db->set ("baz", 3), "Try to set a value");
ok ($db->set ("zot", 4), "Try to set a value");

is_deeply ([sort $db->keys], [qw{bar baz foo zot}], "Get the list of keys");
ok ($db->close, "Closing the file to rewrite it");

ok ($db = CDB::TinyCDB::Wrapper->new ("t/test.cdb"), "Re-open t/test/cdb");
is_deeply ([sort $db->keys], [qw{bar baz foo zot}], "Get the list of keys");

ok ($db->del ("foo"), "Try to delete a value");
is_deeply ([sort $db->keys], [qw{bar baz zot}], "Get the list of keys");
ok ($db->close, "Closing the file to rewrite it");

ok ($db = CDB::TinyCDB::Wrapper->new ("t/test.cdb"), "Re-open t/test/cdb");
is_deeply ([sort $db->keys], [qw{bar baz zot}], "Get the list of keys");

ok ($db->set ("foo", 5), "Add back a value");
is_deeply ([sort $db->keys], [qw{bar baz foo zot}], "Get the list of keys");
ok ($db->abandon, "Abandon our changes");

ok ($db = CDB::TinyCDB::Wrapper->new ("t/test.cdb"), "Re-open t/test/cdb");
is_deeply ([sort $db->keys], [qw{bar baz zot}], "Get the list of keys");
ok ($db->exists ('bar'), "Check whether bar exists");
ok (!$db->exists ('foo'), "Check whether foo exists");
ok ($db->close, "Closing the file to rewrite it");

ok ($db = CDB::TinyCDB::Wrapper->new ("t/test.cdb"), "Re-open t/test/cdb");
ok ($db->set ("foo", 5), "Add back a value");
is_deeply ([$db->each], [qw{bar 2}], "Checking first record key and value");
is_deeply ([$db->each], [qw{baz 3}], "Checking second record key and value");
is_deeply ([$db->each], [qw{foo 5}], "Checking third record key and value");
is_deeply ([$db->each], [qw{zot 4}], "Checking fourth record key and value");

ok ($db = $db->new ("t/test.cdb"), "Re-open t/test/cdb");
ok ($db->close, "Closing the file to rewrite it");

use constant ITER => 1000000;

my $start = time();

ok (sub {
      my $db = CDB::TinyCDB::Wrapper->new ("t/test.cdb");
      my $counter = ITER;
      while ($counter) {
        $db->set ($counter, ITER - $counter);
        ITER - $counter == $db->get ($counter) or die "Mismatch!";
        $counter--;
      }
      undef $db;
      1;
    }->(), "Test large-scale sets");

diag ITER . " loops of sets took " . (time() - $start) . " seconds\n";

$start = time();

ok (sub {
      my $db = CDB::TinyCDB::Wrapper->new ("t/test.cdb");
      my $counter = ITER;
      while ($counter) {
        ITER - $counter == $db->get ($counter) or die "Mismatch!";
        $counter--;
      }
      undef $db;
      1;
    }->(), "Test large-scale gets");

diag ITER . " loops of gets took " . (time() - $start) . " seconds\n";
