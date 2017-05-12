use strict;
use warnings;
use Test::More;
use Archive::Libarchive::Any qw( :all );

# translated from test_archive_match_owner.c

plan skip_all => 'requires archive_match_new' unless eval { Archive::Libarchive::Any->can('archive_match_new') };
plan tests => 4;

my $r;

subtest uid => sub {
  plan tests => 21;
  my $m = archive_match_new();
  ok $m, 'archive_match_new';

  my $e = archive_entry_new();
  ok $e, 'archive_entry_new';
  
  $r = archive_match_include_uid($m, 1000);
  is $r, ARCHIVE_OK, 'archive_match_include_uid 1000';

  $r = archive_match_include_uid($m, 1002);
  is $r, ARCHIVE_OK, 'archive_match_include_uid 1002';

  $r = archive_entry_set_uid($e, 0);
  is $r, ARCHIVE_OK, 'archive_entry_set_uid 0';  
  ok archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded (0)';
  ok archive_match_excluded($m,$e),        'archive_match_excluded (0)';

  $r = archive_entry_set_uid($e, 1000);
  is $r, ARCHIVE_OK, 'archive_entry_set_uid 1000';
  ok !archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded (1000)';
  ok !archive_match_excluded($m,$e),        'archive_match_excluded (1000)';

  $r = archive_entry_set_uid($e, 1001);
  is $r, ARCHIVE_OK, 'archive_entry_set_uid 1001';
  ok archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded (1001)';
  ok archive_match_excluded($m,$e),        'archive_match_excluded (1001)';

  $r = archive_entry_set_uid($e, 1002);
  is $r, ARCHIVE_OK, 'archive_entry_set_uid 1002';
  ok !archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded (1002)';
  ok !archive_match_excluded($m,$e),        'archive_match_excluded (1002)';

  $r = archive_entry_set_uid($e, 1003);
  is $r, ARCHIVE_OK, 'archive_entry_set_uid 1002';
  ok archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded (1003)';
  ok archive_match_excluded($m,$e),        'archive_match_excluded (1003)';
  
  $r = archive_match_free($m);
  is $r, ARCHIVE_OK, 'archive_match_free';

  $r = archive_entry_free($e);
  is $r, ARCHIVE_OK, 'archive_entry_free';
};

subtest gid => sub {
  plan tests => 21;
  my $m = archive_match_new();
  ok $m, 'archive_match_new';

  my $e = archive_entry_new();
  ok $e, 'archive_entry_new';
  
  $r = archive_match_include_gid($m, 1000);
  is $r, ARCHIVE_OK, 'archive_match_include_gid 1000';

  $r = archive_match_include_gid($m, 1002);
  is $r, ARCHIVE_OK, 'archive_match_include_gid 1002';

  $r = archive_entry_set_gid($e, 0);
  is $r, ARCHIVE_OK, 'archive_entry_set_gid 0';  
  ok archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded (0)';
  ok archive_match_excluded($m,$e),        'archive_match_excluded (0)';

  $r = archive_entry_set_gid($e, 1000);
  is $r, ARCHIVE_OK, 'archive_entry_set_gid 1000';
  ok !archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded (1000)';
  ok !archive_match_excluded($m,$e),        'archive_match_excluded (1000)';

  $r = archive_entry_set_gid($e, 1001);
  is $r, ARCHIVE_OK, 'archive_entry_set_gid 1001';
  ok archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded (1001)';
  ok archive_match_excluded($m,$e),        'archive_match_excluded (1001)';

  $r = archive_entry_set_gid($e, 1002);
  is $r, ARCHIVE_OK, 'archive_entry_set_gid 1002';
  ok !archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded (1002)';
  ok !archive_match_excluded($m,$e),        'archive_match_excluded (1002)';

  $r = archive_entry_set_gid($e, 1003);
  is $r, ARCHIVE_OK, 'archive_entry_set_gid 1002';
  ok archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded (1003)';
  ok archive_match_excluded($m,$e),        'archive_match_excluded (1003)';
  
  $r = archive_match_free($m);
  is $r, ARCHIVE_OK, 'archive_match_free';

  $r = archive_entry_free($e);
  is $r, ARCHIVE_OK, 'archive_entry_free';
};

subtest uname => sub {
  plan tests => 21;
  my $m = archive_match_new();
  ok $m, 'archive_match_new';

  my $e = archive_entry_new();
  ok $e, 'archive_entry_new';

  $r = archive_match_include_uname($m, "foo");
  is $r, ARCHIVE_OK, 'archive_match_include_uname foo';

  $r = archive_match_include_uname($m, "bar");
  is $r, ARCHIVE_OK, 'archive_match_include_uname bar';

  $r = archive_entry_set_uname($e, "unknown");
  is $r, ARCHIVE_OK, 'archive_entry_set_uname unknown';
  ok archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded unknown';
  ok archive_match_excluded($m, $e), 'archive_match_excluded unknown';

  $r = archive_entry_set_uname($e, "foo");
  is $r, ARCHIVE_OK, 'archive_entry_set_uname foo';
  ok !archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded foo';
  ok !archive_match_excluded($m, $e), 'archive_match_excluded foo';

  $r = archive_entry_set_uname($e, "foo1");
  is $r, ARCHIVE_OK, 'archive_entry_set_uname foo1';
  ok archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded foo1';
  ok archive_match_excluded($m, $e), 'archive_match_excluded foo1';

  $r = archive_entry_set_uname($e, "bar");
  is $r, ARCHIVE_OK, 'archive_entry_set_uname bar';
  ok !archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded bar';
  ok !archive_match_excluded($m, $e), 'archive_match_excluded bar';

  $r = archive_entry_set_uname($e, "bar1");
  is $r, ARCHIVE_OK, 'archive_entry_set_uname bar1';
  ok archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded bar1';
  ok archive_match_excluded($m, $e), 'archive_match_excluded bar1';

  $r = archive_match_free($m);
  is $r, ARCHIVE_OK, 'archive_match_free';
  
  $r = archive_entry_free($e);
  is $r, ARCHIVE_OK, 'archive_entry_free';
};

subtest gname => sub {
  plan tests => 21;
  my $m = archive_match_new();
  ok $m, 'archive_match_new';

  my $e = archive_entry_new();
  ok $e, 'archive_entry_new';

  $r = archive_match_include_gname($m, "foo");
  is $r, ARCHIVE_OK, 'archive_match_include_gname foo';

  $r = archive_match_include_gname($m, "bar");
  is $r, ARCHIVE_OK, 'archive_match_include_gname bar';

  $r = archive_entry_set_gname($e, "unknown");
  is $r, ARCHIVE_OK, 'archive_entry_set_gname unknown';
  ok archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded unknown';
  ok archive_match_excluded($m, $e), 'archive_match_excluded unknown';

  $r = archive_entry_set_gname($e, "foo");
  is $r, ARCHIVE_OK, 'archive_entry_set_gname foo';
  ok !archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded foo';
  ok !archive_match_excluded($m, $e), 'archive_match_excluded foo';

  $r = archive_entry_set_gname($e, "foo1");
  is $r, ARCHIVE_OK, 'archive_entry_set_gname foo1';
  ok archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded foo1';
  ok archive_match_excluded($m, $e), 'archive_match_excluded foo1';

  $r = archive_entry_set_gname($e, "bar");
  is $r, ARCHIVE_OK, 'archive_entry_set_gname bar';
  ok !archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded bar';
  ok !archive_match_excluded($m, $e), 'archive_match_excluded bar';

  $r = archive_entry_set_gname($e, "bar1");
  is $r, ARCHIVE_OK, 'archive_entry_set_gname bar1';
  ok archive_match_owner_excluded($m, $e), 'archive_match_owner_excluded bar1';
  ok archive_match_excluded($m, $e), 'archive_match_excluded bar1';

  $r = archive_match_free($m);
  is $r, ARCHIVE_OK, 'archive_match_free';
  
  $r = archive_entry_free($e);
  is $r, ARCHIVE_OK, 'archive_entry_free';
};

