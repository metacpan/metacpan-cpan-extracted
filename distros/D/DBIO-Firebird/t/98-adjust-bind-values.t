use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::InterBase;
use DBIO::Firebird::Storage::ODBC;

# OFFLINE (karr k63).
#
# WHY: the value adjustments of the DBD storages (boolean words, numeric
# check, UTF8 flag; k36, k60) belong in core's one seam, _adjust_bind_values,
# which both ways of binding go through. The former override of
# _bind_sth_params assigned to the loop alias of the caller's $bind and so
# wrote 'true'/'false' translations into the caller's list. The claims here:
# the caller's binds are never written to, the storage no longer overrides the
# two methods the seam replaces, and the single and the bulk path hand the
# DBD the same values, literal binds included.

{
  package T::Sth;
  sub new { bless { bound => [], db => { ib_enable_utf8 => 1 } }, shift }
  sub FETCH { $_[0]{db}{ $_[1] } }
  sub bind_param { my ($s, $i, $v, $a) = @_; $s->{bound}[$i - 1] = $v; 1 }
  sub bind_param_inout { my ($s, $i, $r) = @_; $s->{bound}[$i - 1] = $r; 1 }
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

sub sth { my $s = T::Sth->new; $s->{Database} = { ib_enable_utf8 => 1 }; $s }

my @classes = qw(DBIO::Firebird::Storage DBIO::Firebird::Storage::InterBase);
my $bool = { sqlt_datatype => 'boolean', dbic_colname => 'on' };
my $int  = { sqlt_datatype => 'integer', dbic_colname => 'id' };
my $text = { sqlt_datatype => 'varchar', dbic_colname => 'v' };

{
  my $class = 'DBIO::Firebird::Storage::InterBase';
  # (b) where the methods come from
  no strict 'refs';
  ok !defined &{"DBIO::Firebird::Storage::InterBase::_bind_sth_params"},
    'InterBase defines no _bind_sth_params of its own';
  ok !defined &{"DBIO::Firebird::Storage::InterBase::_dbh_execute_for_fetch"},
    'InterBase defines no _dbh_execute_for_fetch of its own';
  ok defined &{"DBIO::Firebird::Storage::InterBase::_adjust_bind_values"},
    'InterBase defines _adjust_bind_values';
  use strict 'refs';
}

for my $class (@classes) {
  my $st = bless { _dbh_details => {} }, $class;

  # (a) the caller's binds are not written to
  my @binds = (
    [ $bool, 'false' ], [ $bool, 'TRUE' ], [ $text, "caf\x{e9}" ], [ $int, '5' ],
  );
  my @pairs = @binds;
  my @copy  = map { [ @$_ ] } @binds;
  my $sth   = sth();
  $st->_bind_sth_params($sth, \@binds, [ (undef) x @binds ]);
  is_deeply \@binds, \@copy, "$class: the caller's bind list keeps its content";
  is $binds[$_], $pairs[$_], "$class: ... and bind $_ is still the caller's pair"
    for 0 .. $#binds;
  is_deeply [ @{ $sth->{bound} }[0, 1] ], [ 0, 1 ], "$class: yet the DBD got the translation";
  ok utf8::is_utf8($sth->{bound}[2]), "$class: ... and the flagged text";

  my $new = $st->_adjust_bind_values(sth(), \@binds, [ (undef) x @binds ]);
  is scalar @$new, scalar @binds, "$class: the seam answers the same number of pairs";
  isnt $new->[0], $binds[0], "$class: ... as new pairs";
  is $binds[0][1], 'false', "$class: ... the caller's value untouched";
  is $new->[0][1], 0, "$class: ... the answer translated";
  is $new->[0][0], $bool, "$class: ... and the meta is the same hash";

  # (d) a scalar ref (bind_param_inout) stays the same reference
  my $out = \(my $slot = 'false');
  my $r = $st->_adjust_bind_values(sth(), [ [ $bool, $out ], [ $int, 1 ] ], [ undef, undef ]);
  is $r->[0][1], $out, "$class: a SCALAR ref stays the very same reference";
  is $$out, 'false', "$class: ... and what it points to is not touched";

  # (c) single and bulk path agree
  my @vals = ('false', 'TRUE', '', 0, 1, undef);
  my $single = sth();
  $st->_bind_sth_params($single, [ map { [ $bool, $_ ] } @vals ], [ (undef) x @vals ]);

  my $pb = [
    [ { dbic_colname => 'id', sqlt_datatype => 'integer', _bind_data_slice_idx => 0 } => 1 ],
    [ { dbic_colname => 'on', sqlt_datatype => 'boolean', _bind_data_slice_idx => 1 } => 1 ],
  ];
  my $bulk = sth();
  $st->_dbh_execute_for_fetch(undef, $bulk, $pb, [qw(id on)],
    [ map { [ 1, $_ ] } @vals ]);
  is_deeply [ map { $_->[1] } @{ $bulk->{tuples} } ], $single->{bound},
    "$class: single and bulk path bind the same boolean values";

  # the same, literal bind \[ '?', [ on => 'false' ] ]
  my $lpb = [
    [ { dbic_colname => 'id', sqlt_datatype => 'integer', _bind_data_slice_idx => 0 } => 1 ],
    [ { dbic_colname => 'on', sqlt_datatype => 'boolean', _bind_data_slice_idx => 1, _literal_bind_subindex => 1 } => 'x' ],
  ];
  my @rows = map { [ 1, \[ '?', [ on => $_ ] ] ] } grep { defined } @vals;
  my $lit = sth();
  $st->_dbh_execute_for_fetch(undef, $lit, $lpb, [qw(id on)], \@rows);
  is_deeply [ map { $_->[1] } @{ $lit->{tuples} } ], [ grep { defined } @{ $single->{bound} } ],
    "$class: a literal bind 'false' on a BOOLEAN column is translated in the bulk path";
  is_deeply ${ $rows[0][1] }, [ '?', [ on => 'false' ] ], "$class: ... the caller's cell untouched";

  # the bulk path still refuses
  my $ok = eval {
    $st->_dbh_execute_for_fetch(undef, sth(), $pb, [qw(id on)], [ [ 1, 'x' ] ]); 1 };
  ok !$ok && $@ =~ /BOOLEAN column 'on'/, "$class: bulk path refuses a non-boolean word";

  # text and numbers in the bulk path
  my $tpb = [
    [ { dbic_colname => 'id', sqlt_datatype => 'integer', _bind_data_slice_idx => 0 } => 1 ],
    [ { dbic_colname => 'v',  sqlt_datatype => 'varchar', _bind_data_slice_idx => 1 } => 1 ],
  ];
  my $t = sth();
  $st->_dbh_execute_for_fetch(undef, $t, $tpb, [qw(id v)], [ [ 1, "caf\x{e9}" ] ]);
  ok utf8::is_utf8($t->{tuples}[0][1]), "$class: bulk text is flagged";
  $ok = eval { $st->_dbh_execute_for_fetch(undef, sth(), $tpb, [qw(id v)], [ ['x', 'a'] ]); 1 };
  ok !$ok && $@ =~ /numeric column 'id'/, "$class: bulk numeric check refuses";
}

done_testing;
