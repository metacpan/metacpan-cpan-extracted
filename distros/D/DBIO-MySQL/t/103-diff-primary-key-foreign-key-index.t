use strict;
use warnings;
use Test::More;

# OFFLINE half of karr k106/k107, two things that went wrong when a primary key
# changes (t/104 has the live half and the measurements):
#
#   S4. _protect_foreign_key_indexes counted the key of the SOURCE as the index
#       that is left over and did not know the key of the target. A foreign key
#       that needs an index the diff drops is only safe while another index is
#       there -- and the key the diff is about to write is one. So a valid
#       upgrade was refused (the index is dropped, "no index of this diff takes
#       its place"), or, where the old key was read in the order of the table,
#       passed and the server refused the DROP INDEX (1553):
#         a. the key of a child table (n) grows to (pid, n): the index the
#            server made for the foreign key over pid is dropped, the new key
#            serves it. The server drops such an index itself when the key
#            that can serve the constraint is created (a DROP INDEX after the
#            key finds nothing, measured on MySQL 8.0), and refuses the drop
#            before it while the constraint is there: so the foreign key is
#            dropped, the index goes, the key changes, the foreign key is added;
#         b. the key (id) of a parent with UNIQUE (a) becomes (a), a foreign
#            key points at a: the UNIQUE index goes, the new key serves it.
#       The drop of the UNIQUE index of b stands AFTER the key (the foreign key
#       needs its index at every moment), not before.
#   S5. A column that is AUTO_INCREMENT has to be a key of the table, and
#       first in it, at every moment. When it leaves the primary key, or is not
#       first in the new one, the statement that changes the key is refused
#       (1075) unless the unique index the target has over that column exists
#       already: the index is created before the key.

use DBIO::MySQL::Diff;

sub col {
  my ($name, %o) = @_;
  return { column_name => $name, column_type => 'int(11)', data_type => 'int', not_null => 1,
    is_pk => 0, is_auto_increment => 0, %o };
}
# a key column: name, position in the key
sub pk { my ($name, $at, %o) = @_; return col($name, is_pk => 1, pk_position => $at, %o) }

sub idx {
  my ($name, $unique, @columns) = @_;
  return $name => { index_name => $name, is_unique => $unique ? 1 : 0, columns => [@columns],
    index_type => 'BTREE', origin => $unique ? 'u' : 'c' };
}
# table => [ [ columns ], { indexes }, [ fks ] ]
sub model {
  my (%t) = @_;
  return {
    tables       => { map { $_ => { table_name => $_, engine => 'InnoDB' } } keys %t },
    columns      => { map { $_ => $t{$_}[0] } keys %t },
    indexes      => { map { $_ => ($t{$_}[1] // {}) } keys %t },
    foreign_keys => { map { $_ => $t{$_}[2] } grep { $t{$_}[2] && @{ $t{$_}[2] } } keys %t },
  };
}
sub fk {
  my ($name, $from, $to, $to_col) = @_;
  return { constraint_name => $name, from_columns => [$from], to_table => $to,
    to_columns => [$to_col], on_update => 'NO ACTION', on_delete => 'NO ACTION' };
}
sub statements {
  my ($source, $target) = @_;
  my $ops = eval { DBIO::MySQL::Diff->new(source => $source, target => $target)->operations };
  return [ "the diff dies: $@" ] unless $ops;
  return [ map { $_->as_sql =~ s/\s+/ /gr } @$ops ];
}

# --- S4 a. the key of the child grows by the column of its foreign key ---
{
  my $parent = [ pk('id', 1) ];
  my $source = model(
    p => [ $parent ],
    c => [ [ col('pid'), pk('n', 1) ], { idx('c_pid_fk', 0, 'pid') }, [ fk('c_pid_fk', 'pid', 'p', 'id') ] ],
  );
  my $target = model(
    p => [ $parent ],
    c => [ [ pk('pid', 1), pk('n', 2) ], {}, [ fk('c_pid_fk', 'pid', 'p', 'id') ] ],
  );
  my @around = (
    'ALTER TABLE `c` DROP FOREIGN KEY `c_pid_fk`;',
    'DROP INDEX `c_pid_fk` ON `c`;',
    'ALTER TABLE `c` DROP PRIMARY KEY, ADD PRIMARY KEY (`pid`, `n`);',
    'ALTER TABLE `c` ADD CONSTRAINT `c_pid_fk` FOREIGN KEY (`pid`) REFERENCES `p`(`id`);',
  );
  is_deeply statements($source, $target), \@around,
    'S4 a: the new key serves the foreign key; the index the server made for it goes with the foreign key around it';

  # the order of the columns of the TABLE is not the order of the key: the old
  # key (n, pid) does not start with pid, so the index c_pid_fk is the foreign
  # key's, and it goes after the key (pid, n)
  my $table_order = model(
    p => [ $parent ],
    c => [ [ pk('pid', 2), pk('n', 1) ], { idx('c_pid_fk', 0, 'pid') }, [ fk('c_pid_fk', 'pid', 'p', 'id') ] ],
  );
  is_deeply statements($table_order, $target), \@around,
    'S4 a: the old key is read in the order of the key, not that of the table';

  # no key of the target serves the foreign key: still refused, as before
  my $none = model(
    p => [ $parent ],
    c => [ [ col('pid'), pk('n', 1) ], {}, [ fk('c_pid_fk', 'pid', 'p', 'id') ] ],
  );
  like statements($source, $none)->[0], qr/the diff dies.*c_pid_fk.*still needs one/s, 'S4 a: where no index of the target takes its place the diff still refuses';
}

# --- S4 b. the UNIQUE key becomes the primary key ---
{
  my $child = [ [ pk('id', 1), col('pa') ], { idx('q_pa_fk', 0, 'pa') }, [ fk('q_pa_fk', 'pa', 'p', 'a') ] ];
  my $source = model(
    p => [ [ pk('id', 1), col('a') ], { idx('p_a', 1, 'a') } ],
    q => $child,
  );
  my $target = model(
    p => [ [ col('id'), pk('a', 1) ], {} ],
    q => $child,
  );
  is_deeply statements($source, $target), [
    'ALTER TABLE `p` DROP PRIMARY KEY, ADD PRIMARY KEY (`a`);',
    'DROP INDEX `p_a` ON `p`;',
  ], 'S4 b: the UNIQUE index a foreign key points at is dropped after the key (a) that replaces it';
}

# --- S5. AUTO_INCREMENT leaves the key, or does not stand first ---
{
  my $source = model(g => [ [ pk('id', 1, is_auto_increment => 1), col('code') ] ]);
  my $target = model(g => [ [ col('id', is_auto_increment => 1), pk('code', 1) ], { idx('g_id', 1, 'id') } ]);
  is_deeply statements($source, $target), [
    'CREATE UNIQUE INDEX `g_id` ON `g` (`id`) USING BTREE;',
    'ALTER TABLE `g` DROP PRIMARY KEY, ADD PRIMARY KEY (`code`);',
  ], 'S5: AUTO_INCREMENT leaves the key: the UNIQUE index over it is created before the key changes';

  $source = model(g => [ [ pk('id', 1, is_auto_increment => 1), pk('k', 2) ] ]);
  $target = model(g => [ [ pk('id', 2, is_auto_increment => 1), pk('k', 1) ], { idx('g_id', 1, 'id') } ]);
  is_deeply statements($source, $target), [
    'CREATE UNIQUE INDEX `g_id` ON `g` (`id`) USING BTREE;',
    'ALTER TABLE `g` DROP PRIMARY KEY, ADD PRIMARY KEY (`k`, `id`);',
  ], 'S5: AUTO_INCREMENT not first in the new key: the same';

  # AUTO_INCREMENT first in the new key needs no index of its own
  $source = model(g => [ [ pk('id', 1, is_auto_increment => 1), col('k') ] ]);
  $target = model(g => [ [ pk('id', 1, is_auto_increment => 1), pk('k', 2) ] ]);
  is_deeply statements($source, $target), [ 'ALTER TABLE `g` DROP PRIMARY KEY, ADD PRIMARY KEY (`id`, `k`);' ],
    'S5: AUTO_INCREMENT first in the new key: one statement, nothing before it';
}

done_testing;
