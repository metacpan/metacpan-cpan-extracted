use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Diff;

# OFFLINE half of karr k113 (t/146 has the live half): a view that reads a
# view being replaced is dropped before it and created again after it, even
# when its own definition did not change.
#
# WHY IT MATTERS. The servers let a view be dropped that others read; the
# reader then answers with 1356 until a view of that name exists again, and
# if the new definition lost a column the reader reads, it stays broken --
# silently, until the first query. Dropping and creating the reader makes the
# server check it against the new definition at apply time, and a reader that
# no longer fits fails loudly there. What this file claims:
#   1. readers are replaced transitively (a reads b reads c, c changes: a, b, c)
#      in the order DROP c's readers first ... CREATE c's readers last;
#   2. a reader that is itself unchanged is still replaced, a view that reads
#      nothing of the changed set is not touched;
#   3. classify counts a replaced reader as changing, never as destructive;
#   4. a reader of a view that is dropped for good or created new is not
#      pulled in (nothing to check it against / it was valid before);
#   5. the same reader reading two replaced views is replaced once.

sub tbl  { return { table_name => $_[0], kind => 'table', engine => 'InnoDB' } }
sub view { return { table_name => $_[0], kind => 'view', view_definition => $_[1] } }
sub model {
  my (%m) = @_;
  return { tables => {}, columns => {}, indexes => {}, foreign_keys => {}, %m };
}
sub diff_of {
  my ($from, $to) = @_;
  my $mk = sub { my $v = shift; model(tables => { t => tbl('t'), map { $_ => view($_, $v->{$_}) } keys %$v }) };
  return DBIO::MySQL::Diff->new(source => $mk->($from), target => $mk->($to));
}
sub sql_of { return [ map { $_->as_sql =~ /^(\w+ VIEW) `([^`]+)`/ ? "$1 $2" : () } @{ $_[0]->operations } ] }

my %OLD = (
  a => 'select `b`.`id` AS `id` from `b`',
  b => 'select `c`.`id` AS `id` from `c`',
  c => 'select `t`.`id` AS `id` from `t`',
  z => 'select `t`.`id` AS `id` from `t`',
);

{
  my %new = (%OLD, c => 'select `t`.`id` AS `id`,1 AS `one` from `t`');
  my $d = diff_of(\%OLD, \%new);
  is_deeply sql_of($d), ['DROP VIEW a', 'DROP VIEW b', 'DROP VIEW c', 'CREATE VIEW c', 'CREATE VIEW b', 'CREATE VIEW a'],
    'c changes: its readers b and a (transitively, both unchanged) are dropped before and created after it';
  my $c = $d->classify;
  is_deeply $c->{counts}, { additive => 3, changing => 3, destructive => 0 }, 'classify: the replaced readers count as changing';
  is $c->{class}, 'changing', '... the class is changing, not destructive';
  ok scalar(grep { $_->can('replaced') && $_->replaced } grep { $_->action eq 'drop' } @{ $d->operations }) == 3,
    '... every drop of the three is marked replaced';
}
{
  my %new = (%OLD, b => 'select `c`.`id` AS `id` from `c` where 1');
  is_deeply sql_of(diff_of(\%OLD, \%new)), ['DROP VIEW a', 'DROP VIEW b', 'CREATE VIEW b', 'CREATE VIEW a'],
    'b changes: its reader a is replaced, c below it and z beside it are not touched';
}
{
  # two readers sorting around the changed view, one reading it via a join
  my %old = (m => 'select `x`.`id` AS `id` from `x` join `y` on 1', x => 'select `t`.`id` AS `id` from `t`', y => 'select `t`.`id` AS `id` from `t`');
  my %new = (%old, x => 'select `t`.`id` AS `id`,1 AS `one` from `t`', y => 'select `t`.`id` AS `id`,2 AS `two` from `t`');
  is_deeply sql_of(diff_of(\%old, \%new)), ['DROP VIEW m', 'DROP VIEW y', 'DROP VIEW x', 'CREATE VIEW x', 'CREATE VIEW y', 'CREATE VIEW m'],
    'a reader of two replaced views is replaced once';
}
{
  # the reader of a view that goes for good is not pulled in
  my %old = (a => 'select `b`.`id` AS `id` from `b`', b => 'select `t`.`id` AS `id` from `t`');
  is_deeply sql_of(diff_of(\%old, { a => $old{a}, b => $old{b} })), [], 'nothing changes: nothing is replaced';
  my %new = (a => 'select `t`.`id` AS `id` from `t`');
  is_deeply sql_of(diff_of(\%old, \%new)), ['DROP VIEW a', 'DROP VIEW b', 'CREATE VIEW a'],
    'a view that reads a removed view and changed itself: dropped once, created once';
}
{
  # a reader sorting before and after, case of the name differs in the reading
  my %old = (aa => 'select * from `Zb`', Zb => 'select `t`.`id` AS `id` from `t`', zz => 'select * from `Zb`');
  my %new = (%old, Zb => 'select `t`.`id` AS `id`,1 AS `one` from `t`');
  is_deeply sql_of(diff_of(\%old, \%new)), ['DROP VIEW zz', 'DROP VIEW aa', 'DROP VIEW Zb', 'CREATE VIEW Zb', 'CREATE VIEW aa', 'CREATE VIEW zz'],
    'readers before and after the changed view in name order are all replaced, in dependency order';
}

done_testing;
