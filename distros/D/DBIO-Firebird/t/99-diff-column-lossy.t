use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Deploy;
use DBIO::Firebird::Diff;
use DBIO::Firebird::Diff::Column;
use DBIO::Deploy::Base;

# OFFLINE (core k399, ADR 0080): the Deploy class runs a diff through core's
# apply, which asks every operation whether it can lose stored data (`lossy`)
# and releases it only with allow_destructive. A type change that keeps every
# value (smallint to integer) runs without the release; one that rounds, cuts
# or rewrites (timestamp to date, float to double precision) does not.
#
# WHY per pair: a pair wrongly called lossless would let an upgrade alter data
# without the caller having said so; a pair wrongly called lossy only costs one
# `allow_destructive => 1`. The list is the short one; t/99-diff-column-
# lossless-live.t shows against a server that the values of each lossless
# pair come back unchanged.

sub info {
  my ($type, $size, %more) = @_;
  return { column_name => 'c', data_type => $type, size => $size, not_null => 0, %more };
}

sub op {
  my ($old, $new, $action) = @_;
  return DBIO::Firebird::Diff::Column->new(
    action => $action // 'alter', table_name => 't', column_name => 'c',
    old_info => $old, new_info => $new,
  );
}

# --- the pairs ----------------------------------------------------------------
my @lossless = (
  [ smallint => 'integer' ], [ smallint => 'bigint' ], [ smallint => 'int128' ],
  [ integer => 'bigint' ], [ integer => 'int128' ], [ bigint => 'int128' ],
  [ smallint => 'double precision' ], [ integer => 'double precision' ],
  [ date => 'timestamp' ],
);
for my $pair (@lossless) {
  my ($from, $to) = @$pair;
  ok !op(info($from), info($to))->lossy, "$from -> $to keeps every value: not lossy";
}

my @lossy = (
  [ integer => 'smallint' ], [ bigint => 'integer' ], [ int128 => 'bigint' ],
  [ bigint => 'double precision' ], [ int128 => 'double precision' ],
  [ smallint => 'float' ], [ float => 'double precision' ],
  [ 'double precision' => 'float' ], [ timestamp => 'date' ], [ timestamp => 'time' ],
  [ date => 'time' ], [ integer => 'varchar' ], [ varchar => 'integer' ],
  [ boolean => 'smallint' ],
);
for my $pair (@lossy) {
  my ($from, $to) = @$pair;
  ok op(info($from, $from =~ /char/ ? 10 : undef), info($to, $to =~ /char/ ? 10 : undef))->lossy,
    "$from -> $to can alter a value: lossy";
}

# --- sizes --------------------------------------------------------------------
ok !op(info(varchar => 10), info(varchar => 20))->lossy, 'varchar(10) -> varchar(20): not lossy';
ok !op(info(varchar => 10), info(varchar => 10))->lossy, 'the same size: not lossy';
ok  op(info(varchar => 20), info(varchar => 10))->lossy, 'varchar(20) -> varchar(10): lossy';
ok !op(info(char => 5), info(varchar => 5))->lossy, 'char(5) -> varchar(5): not lossy';
ok  op(info(char => 5), info(varchar => 9))->lossy, 'char(5) -> varchar(9): lossy (the server pads the value to 9)';
ok  op(info(char => 9), info(varchar => 5))->lossy, 'char(9) -> varchar(5): lossy';
ok !op(info(binary => 5), info(varbinary => 5))->lossy, 'binary(5) -> varbinary(5): not lossy';
ok  op(info(varchar => 5), info('char' => 5))->lossy, 'varchar -> char: lossy (padded)';
ok !op(info(numeric => [9, 2]), info(numeric => [12, 2]))->lossy, 'numeric(9,2) -> numeric(12,2): not lossy';
ok  op(info(numeric => [9, 2]), info(numeric => [12, 3]))->lossy, 'a larger scale rewrites the value: lossy';
ok  op(info(numeric => [9, 2]), info(numeric => [8, 2]))->lossy, 'fewer digits: lossy';
ok  op(info(numeric => [9, 2]), info(decimal => [9, 2]))->lossy, 'numeric -> decimal: lossy, in doubt';
ok  op(info('varchar'), info(varchar => 10))->lossy, 'a live column without size against one with: lossy';

# --- what is no type change ---------------------------------------------------
ok !op(info(integer => undef), info(integer => undef, not_null => 1))->lossy,
  'NOT NULL alone is not lossy';
ok !op(info(varchar => 10), info(varchar => 10, default_value => q{'x'}))->lossy,
  'a default alone is not lossy';
ok !op(info(varchar => 10, default_value => q{'x'}), info(varchar => undef))->lossy,
  'a target that prescribes no size says nothing';
ok !op(undef, info('integer'), 'add')->lossy, 'an add is not lossy';
ok !op(info('integer'), undef, 'drop')->lossy, 'a drop is the guard\'s own (destructive), not lossy';

# --- the whole thing through the deploy class ---------------------------------
sub model {
  my (%columns) = @_;
  return {
    tables => { map { $_ => { table_name => $_, kind => 'table' } } keys %columns },
    columns => \%columns, indexes => {}, unique_constraints => {}, foreign_keys => {},
  };
}
sub col { my ($n, $t, $s) = @_; return { column_name => $n, data_type => $t, size => $s, not_null => 0, default_value => undef, is_pk => 0 } }

{
  package Local::Dbh;
  sub new { bless { asked => [] }, shift }
  sub selectrow_array { push @{ $_[0]{asked} }, $_[1]; return }
  package Local::Storage; sub new { bless { dbh => $_[1] }, $_[0] } sub dbh { $_[0]{dbh} }
  package Local::Schema;  sub new { bless { st => $_[1] }, $_[0] } sub storage { $_[0]{st} }
  package Local::Deploy;
  use base 'DBIO::Firebird::Deploy';
  sub _execute_ddl { my ($self, $dbh, @sql) = @_; push @{ $self->{ran} }, @sql; 1 }
  sub _check_before_apply { my $self = shift; push @{ $self->{checked} }, 1; $self->SUPER::_check_before_apply(@_) }
}

sub deploy { Local::Deploy->new(schema => Local::Schema->new(Local::Storage->new(Local::Dbh->new))) }
sub diff_of {
  my ($from, $to) = @_;
  return DBIO::Firebird::Diff->new(
    source => model(t => [ col('id', 'integer'), col(c => @$from) ]),
    target => model(t => [ col('id', 'integer'), col(c => @$to) ]),
  );
}

for my $m (qw(apply upgrade)) {
  is(DBIO::Firebird::Deploy->can($m), DBIO::Deploy::Base->can($m),
    "Deploy inherits $m from DBIO::Deploy::Base (ADR 0080)");
}
ok(DBIO::Firebird::Deploy->can('_check_before_apply') != DBIO::Deploy::Base->can('_check_before_apply'),
  'Deploy has its own _check_before_apply');

{
  my $d = deploy();
  my $diff = diff_of([ timestamp => undef ], [ date => undef ]);
  eval { $d->apply($diff) };
  isa_ok $@, 'DBIO::Exception', 'a lossy type change without release';
  like "$@", qr/allow_destructive/, '... names the release';
  like "$@", qr/\bt\.c\b/, '... and the column';
  ok !$d->{ran} && !$d->{checked}, '... before the checks and the first statement';

  eval { $d->apply($diff, allow_destructive => 1) };
  is "$@", '', 'with allow_destructive it runs';
  like join("\n", @{ $d->{ran} // [] }), qr/ALTER "c" TYPE date/, '... the ALTER is sent';
}
{
  my $d = deploy();
  my $diff = diff_of([ smallint => undef ], [ integer => undef ]);
  eval { $d->apply($diff) };
  is "$@", '', 'a lossless widening runs without the release';
  ok $d->{ran}, '... and is executed';
  ok $d->{checked}, '... after _check_before_apply';
}
{
  my $d = deploy();
  my $diff = diff_of([ integer => undef ], [ boolean => undef ]);
  eval { $d->apply($diff, allow_destructive => 1) };
  like "$@", qr/refus/i, 'a change the server refuses dies even with the release';
  ok !$d->{ran}, '... before the first statement';
}
{
  my $d = deploy();
  my $diff = diff_of([ timestamp => undef ], [ date => undef ]);
  is $d->apply($diff, dry_run => 1), $diff, 'dry_run returns the diff';
  ok !$d->{ran} && !$d->{checked}, '... executes and checks nothing';
  ok !@{ $d->_dbh->{asked} }, '... and asks the tables nothing';
}

done_testing;
