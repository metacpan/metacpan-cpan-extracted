use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Introspect::Columns;
use DBIO::MySQL::Diff;
use DBIO::MySQL::Diff::Table;

# OFFLINE half of karr k108 (t/125 has the live half): ON UPDATE CURRENT_TIMESTAMP
# is read, compared and written, so a MODIFY COLUMN does not take it off a column.
#
# WHY IT MATTERS. The attribute lives in the column's EXTRA, not in its default.
# The MODIFY COLUMN of a diff wrote type, NOT NULL and DEFAULT only, so a column
# that was `DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` lost the
# ON UPDATE silently with the next type or default change -- and a schema that
# dropped it from a column never got it removed. The model now carries on_update
# (the expression, upper case, 'CURRENT_TIMESTAMP' or 'CURRENT_TIMESTAMP(6)', or
# undef), the diff compares it and every statement it writes puts it back.
#
# The declaration is not a new key: it is the scalar reference a schema already
# writes, default_value => \'CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP' (t/125
# installs that and reads it back). No schema key is built for it.
#
# The EXTRA texts below are what the servers answered on 2026-10-22, MySQL 8.0.30
# and MariaDB 11.8.9:
#   MySQL   'DEFAULT_GENERATED on update CURRENT_TIMESTAMP(6)' / 'on update CURRENT_TIMESTAMP'
#   MariaDB 'on update current_timestamp(6)' / 'on update current_timestamp()'
#
# What the file claims:
#   1. the introspection reads on_update from EXTRA on either server, normalised
#      to one spelling (current_timestamp() == CURRENT_TIMESTAMP), the precision
#      kept, undef where EXTRA has none -- and the default stays what it was;
#   2. a column that gains, loses or changes ON UPDATE is one MODIFY; the same on
#      both sides is none;
#   3. a MODIFY for any other reason (type, default) writes the ON UPDATE of the
#      target; one whose target has none writes none -- which removes it;
#   4. ADD COLUMN and CREATE TABLE of a diff write it;
#   5. a target without the key (target_from_compiled) leaves the live ON UPDATE
#      alone.

{
  package OnUpd::DBH;
  sub new { my ($c, %a) = @_; return bless {%a}, $c }
  sub selectrow_array { return ($_[0]{version}) }
  sub prepare {
    my ($self, $sql) = @_;
    return OnUpd::STH->new if $sql =~ /\binformation_schema\.statistics\b/i;
    return OnUpd::STH->new(@{ $self->{rows} });
  }
  package OnUpd::STH;
  sub new { my $c = shift; return bless { rows => [@_] }, $c }
  sub execute { 1 }
  sub fetchrow_hashref { shift @{ $_[0]{rows} } }
}

sub read_columns {
  my ($version, @cols) = @_;
  my $pos = 0;
  my @rows = map {
    my ($name, $type, $nullable, $default, $extra) = @$_;
    { table_name => 't', column_name => $name, ordinal_position => ++$pos,
      data_type => ($type =~ /\A(\w+)/)[0], column_type => $type, is_nullable => $nullable,
      column_default => $default, column_key => '', extra => $extra,
      character_set_name => undef, collation_name => undef, column_comment => '' }
  } @cols;
  my $c = DBIO::MySQL::Introspect::Columns->fetch(
    OnUpd::DBH->new(version => $version, rows => \@rows), { t => { table_name => 't' } });
  return { map { $_->{column_name} => $_ } @{ $c->{t} } };
}

# 1. introspection
{
  my $my = read_columns('8.0.30',
    [ a => 'timestamp',   'NO',  'CURRENT_TIMESTAMP',    'DEFAULT_GENERATED on update CURRENT_TIMESTAMP' ],
    [ b => 'datetime(6)', 'NO',  'CURRENT_TIMESTAMP(6)', 'DEFAULT_GENERATED on update CURRENT_TIMESTAMP(6)' ],
    [ c => 'datetime',    'YES', undef,                  'on update CURRENT_TIMESTAMP' ],
    [ d => 'datetime',    'NO',  'CURRENT_TIMESTAMP',    'DEFAULT_GENERATED' ],
  );
  is_deeply [ map { $my->{$_}{on_update} } qw(a b c d) ],
    [ 'CURRENT_TIMESTAMP', 'CURRENT_TIMESTAMP(6)', 'CURRENT_TIMESTAMP', undef ],
    'MySQL: on_update is read from EXTRA, precision kept, undef without';
  ok exists $my->{d}{on_update}, '... and the key is there on a column without it (a full description of the column)';
  is_deeply [ map { $my->{$_}{default_value} } qw(a b c d) ],
    [ 'CURRENT_TIMESTAMP', 'CURRENT_TIMESTAMP(6)', undef, 'CURRENT_TIMESTAMP' ],
    '... and the default is what it was';

  my $maria = read_columns('11.8.9-MariaDB-ubu2404',
    [ a => 'timestamp',   'NO',  'current_timestamp()',  'on update current_timestamp()' ],
    [ b => 'datetime(6)', 'NO',  'current_timestamp(6)', 'on update current_timestamp(6)' ],
    [ c => 'datetime',    'YES', 'NULL',                 'on update current_timestamp()' ],
    [ d => 'datetime',    'NO',  'current_timestamp()',  '' ],
  );
  is_deeply [ map { $maria->{$_}{on_update} } qw(a b c d) ],
    [ 'CURRENT_TIMESTAMP', 'CURRENT_TIMESTAMP(6)', 'CURRENT_TIMESTAMP', undef ],
    'MariaDB: the same model from the other spelling';
  is $maria->{c}{default_value}, undef, '... and the keyword NULL is still no default';
}

# the model of one table
sub col {
  my (%c) = @_;
  return { column_name => 'c', data_type => 'datetime', column_type => 'datetime', not_null => 1,
           default_value => 'CURRENT_TIMESTAMP', default_is_expression => 1, on_update => undef, %c };
}
sub model { my ($c) = @_; return { tables => { t => { table_name => 't' } }, columns => { t => [ $c ] }, indexes => {}, foreign_keys => {} } }
sub ops   { my ($old, $new) = @_; return [ @{ DBIO::MySQL::Diff->new(source => model($old), target => model($new))->operations } ] }
my $U = 'CURRENT_TIMESTAMP';

# 2. compare
{
  is scalar(@{ ops(col(), col(on_update => $U)) }), 1, 'gaining ON UPDATE is one change';
  is scalar(@{ ops(col(on_update => $U), col()) }), 1, 'losing ON UPDATE is one change';
  is scalar(@{ ops(col(on_update => $U), col(on_update => 'CURRENT_TIMESTAMP(6)')) }), 1, 'a different precision is one change';
  is scalar(@{ ops(col(on_update => $U), col(on_update => $U)) }), 0, 'the same ON UPDATE is none';
  is scalar(@{ ops(col(), col()) }), 0, 'none on either side is none';
}

# 3. what MODIFY writes
{
  my $ops = ops(col(on_update => $U), col(on_update => $U, data_type => 'timestamp', column_type => 'timestamp'));
  is scalar(@$ops), 1, 'a type change under ON UPDATE is one MODIFY';
  is $ops->[0]->as_sql,
    'ALTER TABLE `t` MODIFY COLUMN `c` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;',
    '... that keeps the ON UPDATE';

  $ops = ops(col(on_update => $U), col(on_update => $U, default_value => '2000-01-01 00:00:00', default_is_expression => 0));
  is $ops->[0]->as_sql,
    q{ALTER TABLE `t` MODIFY COLUMN `c` datetime NOT NULL DEFAULT '2000-01-01 00:00:00' ON UPDATE CURRENT_TIMESTAMP;},
    'a default change under ON UPDATE keeps it';

  $ops = ops(col(on_update => $U), col());
  is $ops->[0]->as_sql, 'ALTER TABLE `t` MODIFY COLUMN `c` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP;',
    'a target without ON UPDATE writes none: the MODIFY removes it';

  $ops = ops(col(default_value => undef, default_is_expression => 0, not_null => 0),
             col(default_value => undef, default_is_expression => 0, not_null => 0, on_update => $U));
  is $ops->[0]->as_sql, 'ALTER TABLE `t` MODIFY COLUMN `c` datetime ON UPDATE CURRENT_TIMESTAMP;',
    'ON UPDATE without a default is written without DEFAULT';
}

# 4. ADD COLUMN, CREATE TABLE
{
  my $src = { tables => { t => { table_name => 't' } }, columns => { t => [] }, indexes => {}, foreign_keys => {} };
  my $ops = [ @{ DBIO::MySQL::Diff->new(source => $src, target => model(col(on_update => $U)))->operations } ];
  is $ops->[0]->as_sql, 'ALTER TABLE `t` ADD COLUMN `c` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;',
    'ADD COLUMN writes ON UPDATE';

  my $create = DBIO::MySQL::Diff::Table->new(action => 'create', table_name => 'n', foreign_keys => [],
    columns => [ col(on_update => $U) ])->as_sql;
  like $create, qr/`c` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP[,\n]/,
    'CREATE TABLE writes ON UPDATE';
}

# 5. compiled target
{
  my $compiled = DBIO::MySQL::Diff->target_from_compiled({ tables => { t => {
    primary_key => [], columns => [ { column_name => 'c', native_type => 'DATETIME', not_null => 1 } ],
  } } });
  my $diff = DBIO::MySQL::Diff->new(source => model(col(on_update => $U)), target => $compiled);
  ok !grep({ $_->as_sql =~ /ON UPDATE/ } @{ $diff->operations }) && !$diff->has_changes,
    'a target from the compiled schema leaves the live ON UPDATE alone'
    or diag explain [ map { $_->as_sql } @{ $diff->operations } ];
}

done_testing;
