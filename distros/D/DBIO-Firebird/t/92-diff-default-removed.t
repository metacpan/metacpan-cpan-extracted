use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Diff;

# OFFLINE (karr k60): a default the declaration no longer has is removed.
#
# The diff took a target without a default for "no opinion" (core's
# desired-state contract: a field the target leaves undef is not compared),
# so a column that lost its default in the schema kept it in the database and
# the diff came back empty (case diff-default-removed). The target of this
# driver's diff is always an introspected model (the temporary database the
# schema is deployed into), and the introspector carries default_value for
# every column, undef where there is none: there undef is "no default". A
# hand-made target model that has no default_value key at all still says
# nothing about it.

sub col {
  my ($name, %more) = @_;
  return { column_name => $name, data_type => 'varchar', size => 20,
           not_null => 0, is_pk => 0, %more };
}

sub model {
  my (@cols) = @_;
  return {
    tables => { t => { table_name => 't', kind => 'table' } },
    columns => { t => \@cols }, indexes => {}, unique_constraints => {}, foreign_keys => {},
  };
}

sub diff_of {
  my ($old, $new) = @_;
  return DBIO::Firebird::Diff->new(source => model($old), target => model($new));
}

# --- the default is gone from the target: DROP DEFAULT ---
{
  my $diff = diff_of(col('c', default_value => q{'x'}), col('c', default_value => undef));
  ok $diff->has_changes, 'a default the target lacks is a difference';
  my @sql = $diff->as_sql;
  like "@sql", qr/ALTER TABLE "t" ALTER "c" DROP DEFAULT;/, '... rendered as DROP DEFAULT';
  unlike "@sql", qr/SET DEFAULT/, '... and nothing else';
}

# --- numeric and expression defaults go the same way ---
for my $default ('0', '7', 'CURRENT_TIMESTAMP') {
  my $diff = diff_of(col('c', default_value => $default), col('c', default_value => undef));
  ok $diff->has_changes, "default $default removed: reported";
}

# --- what stays quiet ---
{
  my $same = diff_of(col('c', default_value => undef), col('c', default_value => undef));
  ok !$same->has_changes, 'no default on either side: no difference';

  my $equal = diff_of(col('c', default_value => q{'x'}), col('c', default_value => q{'x'}));
  ok !$equal->has_changes, 'the same default on both sides: no difference';

  my $silent = diff_of(col('c', default_value => q{'x'}), col('c'));
  ok !$silent->has_changes, 'a target model with no default_value key says nothing about it';

  my $gained = diff_of(col('c', default_value => undef), col('c', default_value => q{'y'}));
  like join(' ', $gained->as_sql), qr/SET DEFAULT 'y'/, 'a default gained is still SET DEFAULT';

  my $changed = diff_of(col('c', default_value => q{'x'}), col('c', default_value => q{'y'}));
  like join(' ', $changed->as_sql), qr/SET DEFAULT 'y'/, 'a default changed is still SET DEFAULT';
}

done_testing;
