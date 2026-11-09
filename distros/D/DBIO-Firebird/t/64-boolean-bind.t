use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::InterBase;
use DBIO::Firebird::Storage::ODBC;

# OFFLINE (karr k36).
#
# WHY: DBD::Firebird 1.39 binds a parameter as text and, for a BOOLEAN column,
# takes the Perl truth of the text -- 'false' reaches the server as TRUE
# (measured live, t/26-boolean-live.t). _adjust_bind_values of the DBD storages
# is where every bound value passes (core's _bind_sth_params and the rows of
# _dbh_execute_for_fetch go through it, karr k63), so it must translate the two SQL words, pass
# 1 / 0 / undef, and refuse the rest, only for a bind that says it is a boolean.
# The ODBC storage does not take this: the behaviour is the DBD's, not the
# engine's (ADR 0010), and has not been measured for DBD::ODBC.

{
  package T::Sth;
  sub new { bless { bound => [] }, shift }
  sub bind_param { my ($s, $i, $v, $a) = @_; $s->{bound}[$i - 1] = $v; 1 }
  sub execute_for_fetch {
    my ($s, $fetch, $status) = @_;
    my $n = 0;
    while (my $t = $fetch->()) { push @{ $s->{tuples} }, $t; $n++ }
    return $n;
  }
  sub err { undef }
  sub errstr { undef }
  sub finish { 1 }
}

sub bound {
  my ($class, @binds) = @_;
  my $st  = bless {}, $class;
  my $sth = T::Sth->new;
  $st->_bind_sth_params($sth, \@binds, [ (undef) x @binds ]);
  return $sth->{bound};
}

my $bool = { sqlt_datatype => 'boolean', dbic_colname => 'on' };

for my $class (qw(DBIO::Firebird::Storage DBIO::Firebird::Storage::InterBase)) {
  is_deeply bound($class, map { [ $bool, $_ ] } 1, 0, '1', '0', undef),
    [ 1, 0, '1', '0', undef ], "$class: 1, 0 and undef pass as they are";
  is_deeply bound($class, [ $bool, '' ]), [ 0 ],
    "$class: '' is what the DBD reads for FALSE, and binds as 0";
  is_deeply bound($class, map { [ $bool, $_ ] } 'true', 'False', 'TRUE', 'false'),
    [ 1, 0, 1, 0 ], "$class: 'true' / 'false' are translated, in any case";

  for my $bad ('x', 2, 'yes', ' 1') {
    my $ok = eval { bound($class, [ $bool, $bad ]); 1 };
    ok !$ok && $@ =~ /BOOLEAN column 'on'/ && $@ !~ /\Q'$bad'\E/,
      "$class: '$bad' is refused, naming the column and not the value";
  }

  is_deeply bound($class, [ { sqlt_datatype => 'varchar' }, 'false' ], [ {}, 'x' ]),
    [ 'false', 'x' ], "$class: a bind that is not a boolean is left alone";
}

# the bulk path: rows of [ id, flag ], the flag column is slice index 1
sub bulk {
  my ($class, @rows) = @_;
  my $st  = bless { _dbh_details => {} }, $class;
  my $sth = T::Sth->new;
  my $pb  = [
    [ { dbic_colname => 'id',   sqlt_datatype => 'integer', _bind_data_slice_idx => 0 } => 1 ],
    [ { dbic_colname => 'flag', sqlt_datatype => 'boolean', _bind_data_slice_idx => 1 } => 1 ],
  ];
  $st->_dbh_execute_for_fetch(undef, $sth, $pb, [qw(id flag)], \@rows);
  return $sth->{tuples};
}

for my $class (qw(DBIO::Firebird::Storage DBIO::Firebird::Storage::InterBase)) {
  my @rows = ([ 1, 'false' ], [ 2, 'TRUE' ], [ 3, '' ], [ 4, 0 ], [ 5, undef ], [ 6, 1 ]);
  is_deeply bulk($class, @rows),
    [ [1, 0], [2, 1], [3, 0], [4, 0], [5, undef], [6, 1] ],
    "$class: populate's bulk path translates the boolean column";
  is $rows[0][1], 'false', "$class: ... and leaves the caller's rows alone";

  my $ok = eval { bulk($class, [ 1, 1 ], [ 2, 'x' ]); 1 };
  ok !$ok && $@ =~ /BOOLEAN column 'flag'/,
    "$class: bulk path refuses a value that is none of the boolean spellings";
}

# literal binds in the bulk path: populate([[qw/id on/], [1, \['?', [on => 'false']]]])
# -- the cell holds the bind at _literal_bind_subindex, and it is a boolean
sub bulk_literal {
  my ($class, @values) = @_;
  my $st  = bless { _dbh_details => {} }, $class;
  my $sth = T::Sth->new;
  my $pb  = [
    [ { dbic_colname => 'id', sqlt_datatype => 'integer', _bind_data_slice_idx => 0 } => 1 ],
    [ { dbic_colname => 'on', sqlt_datatype => 'boolean', _bind_data_slice_idx => 1, _literal_bind_subindex => 1 } => 'x' ],
  ];
  my @rows = map { [ $_->[0], \[ '?', $_->[1] ] ] } @values;
  $st->_dbh_execute_for_fetch(undef, $sth, $pb, [qw(id on)], \@rows);
  return ($sth->{tuples}, \@rows);
}
for my $class (qw(DBIO::Firebird::Storage DBIO::Firebird::Storage::InterBase)) {
  my ($got, $rows) = bulk_literal($class,
    [ 1, [ on => 'false' ] ], [ 2, [ on => 'TRUE' ] ], [ 3, [ on => '' ] ], [ 4, [ on => 1 ] ],
    [ 5, [ on => undef ] ], [ 6, 'false' ]);
  is_deeply $got, [ [1, 0], [2, 1], [3, 0], [4, 1], [5, undef], [6, 0] ],
    "$class: a literal bind on a boolean column is translated in the bulk path";
  is_deeply ${ $rows->[0][1] }, [ '?', [ on => 'false' ] ], "$class: ... and the caller's cell is left alone";

  my $ok = eval { bulk_literal($class, [ 1, [ on => 1 ] ], [ 2, [ on => 'x' ] ]); 1 };
  ok !$ok && $@ =~ /BOOLEAN column 'on'/, "$class: a literal bind that is no boolean spelling is refused, naming the column";
}

is_deeply bound('DBIO::Firebird::Storage::ODBC', [ $bool, 'false' ]), [ 'false' ],
  'ODBC storage: no translation';

done_testing;
