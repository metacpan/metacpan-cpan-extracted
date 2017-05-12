use strict;
use warnings;
use Test::More;
use Archive::Libarchive::Any qw( :all );

plan skip_all => 'requires archive_read_disk_set_gname_lookup' unless Archive::Libarchive::Any->can('archive_read_disk_set_gname_lookup');
plan tests => 5;

# based on test_read_disk.c

my $a = archive_read_disk_new();
ok $a, 'archive_read_disk_new';

subtest 'Default uname/gname lookups always return undef.' => sub {
  plan tests => 2;
  is archive_read_disk_gname($a, 0), undef, 'archive_read_disk_gname';
  is archive_read_disk_uname($a, 0), undef, 'archive_read_disk_uname';
};

subtest 'Register some weird lookup functions.' => sub {
  plan tests => 5;
  my $gmagic = 0x13579;
  
  my $r = eval { archive_read_disk_set_gname_lookup($a, \$gmagic, \&gname_lookup, \&gname_cleanup) };
  diag $@ if $@;
  is $r, ARCHIVE_OK, 'archive_read_disk_set_gname_lookup';
  is archive_read_disk_gname($a, 0), 'NOTFOOGROUP', 'gname 0 = NOTFOOGROUP';
  is archive_read_disk_gname($a, 1), 'FOOGROUP',    'group 1 = FOOGROUP';
  
  $r = eval { archive_read_disk_set_gname_lookup($a, undef, undef, undef) };
  diag if $@;
  is $r, ARCHIVE_OK, 'De-register.';
  is $gmagic, 0x2468, 'Ensure our cleanup function got called.';
};

subtest 'Same thing with uname lookup....' => sub {
  plan tests => 5;
  my $umagic = 0x1234;
  my $r = eval { archive_read_disk_set_uname_lookup($a, \$umagic, \&uname_lookup, \&uname_cleanup) };
  diag $@ if $@;
  is $r, ARCHIVE_OK, 'archive_read_disk_set_uname_lookup';
  
  is archive_read_disk_uname($a, 0), "NOTFOO", 'uname 0 = NOTFOO';
  is archive_read_disk_uname($a, 1), "FOO",    'uname 1 = FOO';
  
  $r = eval { archive_read_disk_set_uname_lookup($a, undef, undef, undef) };
  diag $@ if $@;
  is $r, ARCHIVE_OK, 'De-register.';
  is $umagic, 0x2345, 'Ensure our cleanup function got called.';
};

subtest 'cleanup' => sub {
  plan tests => 1;
  my $r = archive_read_free($a);
  is $r, ARCHIVE_OK, 'archive_read_free';
};

sub gname_cleanup
{
  my($data) = @_;
  die unless $$data == 0x13579;
  $$data = 0x2468;
}

sub gname_lookup
{
  my($data, $gid) = @_;
  return "FOOGROUP" if $gid == 1;
  return "NOTFOOGROUP";
}

sub uname_cleanup
{
  my($data) = @_;
  die unless $$data == 0x1234;
  $$data = 0x2345;
}

sub uname_lookup
{
  my($data, $uid) = @_;
  return "FOO" if $uid == 1;
  return "NOTFOO";
}
