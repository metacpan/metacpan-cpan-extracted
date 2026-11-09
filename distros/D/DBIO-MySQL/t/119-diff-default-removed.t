use strict;
use warnings;
use Test::More;

# OFFLINE half of karr k95 (t/120 has the live half): a default that is in the
# live column and that the target no longer names is removed.
#
# WHY: the target of an upgrade is the introspection of the temporary database,
# where default_value undef means "this column has no default". The column
# comparison read undef as "not prescribed" (the desired-state contract of
# DBIO::Diff::Compare) and reported nothing, so the default stayed. A target
# that comes from the compiled schema (target_from_compiled) does stay silent
# about a column without a default: a portable schema that names none does not
# prescribe "none" there, and the live column is left alone.
#
# What the file claims:
#   1. a target column as the introspection makes it (default_is_expression
#      present, default_value undef) against a live column with a default is a
#      MODIFY, and the statement carries no DEFAULT -- which is what removes it;
#      that holds for the MySQL form (literal, and expression with EXTRA
#      DEFAULT_GENERATED) and the MariaDB form (quoted literal);
#   2. no default on either side is no change;
#   3. a target from target_from_compiled without a default leaves the live
#      default alone;
#   4. a default of the target still wins over everything above.

use DBIO::MySQL::Diff;

sub col {
  my (%c) = @_;
  return { column_name => 'c', data_type => 'int', column_type => 'int', not_null => 0, %c };
}

# The introspection's shape, as t/44 has it for each server.
my %live = (
  'MySQL literal'    => col(default_value => '5', default_is_expression => 0, extra => ''),
  'MySQL expression' => col(data_type => 'timestamp', column_type => 'timestamp',
                            default_value => 'CURRENT_TIMESTAMP', default_is_expression => 1,
                            extra => 'DEFAULT_GENERATED'),
  'MariaDB literal'  => col(default_value => 'x', default_is_expression => 0, data_type => 'varchar', column_type => 'varchar(20)'),
);
my %none = (
  'MySQL literal'    => col(default_value => undef, default_is_expression => 0),
  'MySQL expression' => col(data_type => 'timestamp', column_type => 'timestamp', default_value => undef, default_is_expression => 0),
  'MariaDB literal'  => col(default_value => undef, default_is_expression => 0, data_type => 'varchar', column_type => 'varchar(20)'),
);

sub model { my ($c) = @_; return { tables => { t => { table_name => 't' } }, columns => { t => [ $c ] }, indexes => {}, foreign_keys => {} } }
sub ops   { my ($old, $new) = @_; return [ @{ DBIO::MySQL::Diff->new(source => model($old), target => model($new))->operations } ] }

for my $form (sort keys %live) {
  my $ops = ops($live{$form}, $none{$form});
  is scalar(@$ops), 1, "$form: a default the target no longer has is one change" or next;
  unlike $ops->[0]->as_sql, qr/DEFAULT/, '... and its MODIFY COLUMN carries no DEFAULT';
  like $ops->[0]->as_sql, qr/\AALTER TABLE `t` MODIFY COLUMN `c` /, '... on that column';
  is scalar(@{ ops($none{$form}, $none{$form}) }), 0, "$form: no default on either side is no change";
}

# A compiled schema that names no default does not prescribe "none".
{
  my $compiled = DBIO::MySQL::Diff->target_from_compiled({ tables => { t => {
    primary_key => [], columns => [ { column_name => 'c', native_type => 'BIGINT', not_null => 0 } ],
  } } });
  my $live = col(data_type => 'bigint', column_type => 'bigint(20)', default_value => '5', default_is_expression => 0);
  my $diff = DBIO::MySQL::Diff->new(source => model($live), target => $compiled);
  ok !$diff->has_changes, 'a target from the compiled schema without a default leaves the live default alone'
    or diag explain [ map { $_->as_sql } @{ $diff->operations } ];
}

# A default the target names still decides.
{
  my $ops = ops($live{'MySQL literal'}, col(default_value => '6', default_is_expression => 0));
  is scalar(@$ops), 1, 'a different default is a change';
  like $ops->[0]->as_sql, qr/DEFAULT '6';\z/, '... that writes the new one';
}

done_testing;
