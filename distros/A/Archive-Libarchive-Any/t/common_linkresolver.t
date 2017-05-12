use strict;
use warnings;
use Test::More;
use Archive::Libarchive::Any qw( :all );

plan skip_all => 'test requires archive_entry_linkify' unless Archive::Libarchive::Any->can('archive_entry_linkify');
plan tests => 2;

subtest test_linkify_tar => sub
{
  plan tests => 17;
  my $r;
  
  my $lr = eval { archive_entry_linkresolver_new() };
  diag $@ if $@;
  ok $lr, 'archive_entry_linkresolver_new';
  
  $r = eval { archive_entry_linkresolver_set_strategy($lr, ARCHIVE_FORMAT_TAR_USTAR) };
  diag $@ if $@;
  is $r, ARCHIVE_OK, 'archive_entry_linkresolver_set_strategy';
  
  my $entry = archive_entry_new();
  archive_entry_set_pathname($entry, "test1");
  archive_entry_set_ino($entry, 1);
  archive_entry_set_dev($entry, 2);
  archive_entry_set_nlink($entry, 1);
  archive_entry_set_size($entry, 10);
  
  my $e2;
  $r = eval { archive_entry_linkify($lr, $entry, $e2) };
  diag $@ if $@;
  is $r, ARCHIVE_OK, 'archive_entry_linkify';
  is $e2, undef, 'e2 == undef';  
  is archive_entry_size($entry), 10, 'size == 10';
  is archive_entry_pathname($entry), 'test1', 'pathname = test1';
  
  archive_entry_set_pathname($entry, "test2");
  archive_entry_set_nlink($entry, 2);
  archive_entry_set_ino($entry, 2);
  $r = eval { archive_entry_linkify($lr, $entry, $e2) };
  diag $@ if $@;
  is $r, ARCHIVE_OK, 'archive_entry_linkify';
  is $e2, undef, 'e2 == undef';
  is archive_entry_pathname($entry), 'test2', 'pathname = test2';
  is archive_entry_hardlink($entry), undef, 'hardlink = undef';
  is archive_entry_size($entry), 10, 'size == 10';
  
  $r = eval { archive_entry_linkify($lr, $entry, $e2) };
  diag $@ if $@;
  is $r, ARCHIVE_OK, 'archive_entry_linkify';
  is $e2, undef, 'e2 == undef';
  is archive_entry_pathname($entry), 'test2';
  is archive_entry_hardlink($entry), 'test2';
  is archive_entry_size($entry), 0;
  
  archive_entry_free($entry);
  archive_entry_free($e2) if $e2;
  
  $r = eval { archive_entry_linkresolver_free($lr) };
  diag $@ if $@;
  is $r, ARCHIVE_OK, 'archive_entry_linkresolver_free';

};

subtest test_linkify_new_cpio => sub
{
  plan tests => 18;
  my $r;
  
  # Initialize the resolver.
  my $resolver = archive_entry_linkresolver_new();
  ok $resolver, 'archive_entry_linkresolver_new';
  $r = archive_entry_linkresolver_set_strategy($resolver, ARCHIVE_FORMAT_CPIO_SVR4_NOCRC);
  is $r, ARCHIVE_OK, 'archive_entry_linkresolver_set_strategy';

  # Create an entry with only 1 link and try to linkify it.
  my $entry = archive_entry_new();
  ok $entry, 'archive_entry_new';
  archive_entry_set_pathname($entry, "test1");
  archive_entry_set_ino($entry, 1);
  archive_entry_set_dev($entry, 2);
  archive_entry_set_nlink($entry, 1);
  archive_entry_set_size($entry, 10);
  my $e2;
  $r = archive_entry_linkify($resolver, $entry, $e2);
  is $r, ARCHIVE_OK, 'archive_entry_linkify';

  # Shouldn't have been changed.  
  is $e2, undef, 'e2 = undef';
  is archive_entry_size($entry), 10, 'archive_entry_size($entry) = 10';
  is archive_entry_pathname($entry), 'test1', 'archive_entry_pathname($entry) = test1';
  
  # Now, try again with an entry that has 3 links.
  archive_entry_set_pathname($entry, "test2");
  archive_entry_set_nlink($entry, 3);
  archive_entry_set_ino($entry, 2);
  archive_entry_linkify($resolver, $entry, $e2);
  
  # First time, it just gets swallowed.
  is $entry, undef, 'entry = undef';
  is $e2, undef, 'e2 = undef';
  
  # Match again
  $entry = archive_entry_new();
  ok $entry, 'archive_entry_new';
  archive_entry_set_pathname($entry, "test3");
  archive_entry_set_ino($entry, 2);
  archive_entry_set_dev($entry, 2);
  archive_entry_set_nlink($entry, 2);
  archive_entry_set_size($entry, 10);
  archive_entry_linkify($resolver, $entry, $e2);

  # Should get back "test2" and nothing else.
  is archive_entry_pathname($entry), 'test2', 'archive_entry_pathname($entry) = test2';
  is archive_entry_size($entry), 0, 'archive_entry_size($entry) = 0';
  archive_entry_free($entry) if $entry;
  is $e2, undef, 'e2 = undef';
  archive_entry_free($e2) if $e2; # this should be a no-op.
  
  # Match a third time.
  $entry = archive_entry_new();
  archive_entry_set_pathname($entry, "test4");
  archive_entry_set_ino($entry, 2);
  archive_entry_set_dev($entry, 2);
  archive_entry_set_nlink($entry, 3);
  archive_entry_set_size($entry, 10);
  archive_entry_linkify($resolver, $entry, $e2);

  # Should get back "test3".
  is archive_entry_pathname($entry), 'test3', 'archive_entry_pathname($entry) = test3';
  is archive_entry_size($entry), 0, 'archive_entry_size($entry) = 0';
  
  # Since "test4" was the last link, should get it back also.
  is eval { archive_entry_pathname($e2) }, 'test4', 'archive_entry_pathname(e2) = test4';
  diag $@ if $@;
  is eval { archive_entry_size($e2) }, 10, 'archive_entry_size($e2) = 10';
  diag $@ if $@;

  note "entry = $entry";
  note "e2 =  = $e2";
  
  archive_entry_free($entry);
  archive_entry_free($e2);
  $r = archive_entry_linkresolver_free($resolver);
  is $r, ARCHIVE_OK, 'archive_entry_linkresolver_free';
};
