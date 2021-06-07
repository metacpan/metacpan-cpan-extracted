use strict;
use warnings;
use Test::More;
use Archive::Libarchive::Any qw( :all );

foreach my $symbol (map { "archive_entry_sparse_$_" } qw( count reset next clear add_entry ))
{
  plan skip_all => "test requires $symbol"
    unless Archive::Libarchive::Any->can($symbol);
}

plan tests => 4;

my $r;
my $e = archive_entry_new();

archive_entry_set_size($e, 2046);

subtest 'example with no sparse stuff' => sub {
  plan tests => 3;

  is eval { archive_entry_sparse_count($e) }, 0, 'archive_entry_sparse_count = 0';
  diag $@ if $@;

  is eval { archive_entry_sparse_reset($e) }, 0, 'archive_entry_sparse_reset = 0';
  diag $@ if $@;

  $r = eval { archive_entry_sparse_next($e, my $o, my $l) };

  is $r, ARCHIVE_WARN, 'archive_entry_sparse_next';
  diag $@ if $@;
};

subtest 'add sparsenesss' => sub {
  plan tests => 2;

  $r = eval { archive_entry_sparse_add_entry($e, 52, 100) };
  diag $@ if $@;

  is $r, ARCHIVE_OK, 'archive_entry_sparse_add_entry(e,52,100)';

  $r = eval { archive_entry_sparse_add_entry($e, 512, 87) };
  diag $@ if $@;

  is $r, ARCHIVE_OK, 'archive_entry_sparse_add_entry(e,512,87)';

};

subtest 'fetch sparseness' => sub {
  plan tests => 9;

  is eval { archive_entry_sparse_count($e) }, 2, 'archive_entry_sparse_count = 2';
  diag $@ if $@;

  is eval { archive_entry_sparse_reset($e) }, 2, 'archive_entry_sparse_reset = 2';
  diag $@ if $@;

  foreach my $pair ([52,100],[512,87])
  {
    my($expected_offset,$expected_length) = @$pair;
    my $actual_offset;
    my $actual_length;
    $r = eval { archive_entry_sparse_next($e, $actual_offset, $actual_length) };
    diag $@ if $@;
    is $r, ARCHIVE_OK, 'archive_entry_sparse_next';
    is $actual_offset, $expected_offset, "offset = $expected_offset";
    is $actual_length, $expected_length, "length = $expected_length";
  }

  $r = eval { archive_entry_sparse_next($e, my $o, my $l) };

  is $r, ARCHIVE_WARN, 'archive_entry_sparse_next';
  diag $@ if $@;
};

subtest 'clear sparseness' => sub {
  plan tests => 4;

  $r = eval { archive_entry_sparse_clear($e) };
  is $r, ARCHIVE_OK, 'archive_entry_sparse_clear';

  is eval { archive_entry_sparse_count($e) }, 0, 'archive_entry_sparse_count = 0';
  diag $@ if $@;

  is eval { archive_entry_sparse_reset($e) }, 0, 'archive_entry_sparse_reset = 0';
  diag $@ if $@;

  $r = eval { archive_entry_sparse_next($e, my $o, my $l) };

  is $r, ARCHIVE_WARN, 'archive_entry_sparse_next';
  diag $@ if $@;
};
