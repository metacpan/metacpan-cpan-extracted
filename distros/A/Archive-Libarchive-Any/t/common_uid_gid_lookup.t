use strict;
use warnings;
use Test::More;
use Archive::Libarchive::Any qw( :all );

plan skip_all => 'requires archive_write_disk_gid' unless Archive::Libarchive::Any->can('archive_write_disk_gid');
plan tests => 7;

# based on test_write_disk_lookup.c

my $gmagic = 0x13579;
my $umagic = 0x1234;

my $a = archive_write_disk_new();
ok $a, 'archive_write_disk_new';

subtest 'Default uname/gname lookup always return ID.' => sub {
  plan tests => 5;
  is archive_write_disk_gid($a, '', 0), 0, 'gid "",0 = 0';
  is archive_write_disk_gid($a, 'root', 12), 12, 'gid root,12 = 12';
  is archive_write_disk_gid($a, 'wheel', 12), 12, 'gid wheel,12 = 12';
  is archive_write_disk_uid($a, '', 0), 0, 'uid "",0 = 0';
  is archive_write_disk_uid($a, 'root', 18), 18, 'uid root,18 = 18';
};

subtest 'Register some weird lookup functions' => sub {
  plan tests => 1;
  my $r = eval { archive_write_disk_set_group_lookup($a, \$gmagic, \&group_lookup, \&group_cleanup) };
  diag $@ if $@;
  is $r, ARCHIVE_OK, 'archive_write_disk_set_group_lookup';
};

subtest 'Verify that our new function got called.' => sub {
  plan tests => 2;
  is archive_write_disk_gid($a, "FOOGROUP",    8), 73, 'gid FOOGROUP    8 = 73';
  is archive_write_disk_gid($a, "NOTFOOGROUP", 8),  1, 'gid NOTFOOGROUP 8 = 1';
};

subtest 'De-register.' => sub {
  plan tests => 2;
  my $r = eval { archive_write_disk_set_group_lookup($a, undef, undef, undef) };
  diag $@ if $@;
  is $r, ARCHIVE_OK, 'archive_write_disk_set_group_lookup';
  is $gmagic, 0x2468, 'Ensure our cleanup function got called.';
};

subtest 'Same thing with uname lookup....' => sub {
  plan tests => 5;
  my $r = eval { archive_write_disk_set_user_lookup($a, \$umagic, \&user_lookup, \&user_cleanup) };
  diag $@ if $@;
  is $r, ARCHIVE_OK, 'archive_write_disk_set_user_lookup';
  
  is archive_write_disk_uid($a, "FOO",    0),  2, 'uid FOO    0 = 2';
  is archive_write_disk_uid($a, "NOTFOO", 1), 74, 'uid NOTFOO 1 = 74';
  
  $r = eval { archive_write_disk_set_user_lookup($a, undef, undef, undef) };
  diag $@ if $@;
  is $r, ARCHIVE_OK, 'archive_write_disk_set_user_lookup';
  is $umagic, 0x2345, 'Ensure our cleanup function got called';
};

subtest 'cleanup' => sub {
  plan tests => 1;
  my $r = archive_write_free($a);
  is $r, ARCHIVE_OK, 'archive_write_free';
};

sub group_cleanup
{
  my($data) = @_;
  die unless $$data == 0x13579;
  $$data = 0x2468;
}

sub group_lookup
{
  my($data, $name, $gid) = @_;
  die unless $$data == 0x13579;
  return 1 if $name ne 'FOOGROUP';
  return 73;
}

sub user_cleanup
{
  my($data) = @_;
  die unless $$data == 0x1234;
  $$data = 0x2345;
}

sub user_lookup
{
  my($data, $name, $uid) = @_;
  die unless $$data == 0x1234;
  return 2 if $name eq 'FOO';
  return 74;
}
