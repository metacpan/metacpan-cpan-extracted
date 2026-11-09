use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::InterBase;
use DBIO::Firebird::Storage::ODBC;

# OFFLINE (karr k60, case bind-empty-string).
#
# WHY: DBD::Firebird converts the text it is given for a numeric parameter in
# Perl (SvIV / SvNV) and not on the server. Measured on Firebird 5.0.4 with
# DBD::Firebird 1.39, INSERT into an INTEGER, BIGINT, DOUBLE PRECISION and
# NUMERIC(9,2) column: '', ' ' and 'x' are stored as 0, '5x' as 5 (the DBD
# warns "Argument ... isn't numeric" and goes on) -- where the server
# answers "conversion error from string" to the same text as a literal or in
# a CAST. A row the server would have refused is stored, silently, as another
# number. _bind_sth_params of the DBD storages is where every bound value
# passes, so a value that is no number for a numeric column is refused there,
# before the DBD reads it. The column is known from the bind's sqlt_datatype;
# a bind without one is left as written. The ODBC storage is not touched (the
# behaviour is the DBD's, not the engine's; ADR 0010).

{
  package T::Sth;
  sub new { my ($c, %a) = @_; bless { bound => [], %a }, $c }
  sub bind_param { my ($s, $i, $v, $a) = @_; $s->{bound}[$i - 1] = $v; 1 }
  sub bind_param_inout { my ($s, $i, $r, $max, $a) = @_; $s->{bound}[$i - 1] = $$r; 1 }
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
  my $st  = bless { _dbio_connect_attributes => { LongReadLen => 8000 } }, $class;
  my $sth = T::Sth->new;
  $st->_bind_sth_params($sth, \@binds, [ (undef) x @binds ]);
  return $sth->{bound};
}

my @NUMERIC = qw(integer int smallint bigint tinyint numeric decimal float double real);

for my $class (qw(DBIO::Firebird::Storage DBIO::Firebird::Storage::InterBase)) {
  for my $type (@NUMERIC) {
    my $info = { sqlt_datatype => $type, dbic_colname => 'n' };
    is_deeply bound($class, map { [ $info, $_ ] } 5, '5', ' 7 ', '-3', '1.5', '0', 0, '1e3', '.5', 2.5, undef),
      [ 5, '5', ' 7 ', '-3', '1.5', '0', 0, '1e3', '.5', 2.5, undef ],
      "$class, $type: numbers and undef pass as they are";
  }

  my $int = { sqlt_datatype => 'integer', dbic_colname => 'n' };
  for my $bad ('', ' ', 'x', '5x', 'abc', '1,5', '0x10', '--1') {
    my $ok = eval { bound($class, [ $int, $bad ]); 1 };
    ok !$ok && $@ =~ /refus/i && $@ =~ /numeric column 'n'/ && $@ !~ /\Q'$bad'\E/,
      "$class: '$bad' is refused for an integer column, naming the column and not the value";
    isa_ok $@, 'DBIO::Exception' unless $ok;
  }

  is_deeply bound($class, [ { sqlt_datatype => 'varchar' }, 'x' ], [ { sqlt_datatype => 'text' }, '' ],
                  [ {}, 'x' ], [ { sqlt_datatype => 'date' }, 'x' ]),
    [ 'x', '', 'x', 'x' ], "$class: a bind that is not numeric is left alone (the server judges a date)";
}

is_deeply bound('DBIO::Firebird::Storage::ODBC', [ { sqlt_datatype => 'integer', dbic_colname => 'n' }, 'x' ]), [ 'x' ],
  'ODBC storage: no check';

# the bulk path
sub bulk {
  my ($class, @rows) = @_;
  my $st  = bless { _dbh_details => {}, _dbio_connect_attributes => { LongReadLen => 8000 } }, $class;
  my $sth = T::Sth->new;
  my $pb  = [
    [ { dbic_colname => 'id', sqlt_datatype => 'integer', _bind_data_slice_idx => 0 } => 1 ],
    [ { dbic_colname => 'n',  sqlt_datatype => 'numeric', _bind_data_slice_idx => 1 } => 1 ],
    [ { dbic_colname => 's',  sqlt_datatype => 'varchar', _bind_data_slice_idx => 2 } => 1 ],
  ];
  $st->_dbh_execute_for_fetch(undef, $sth, $pb, [qw(id n s)], \@rows);
  return $sth->{tuples};
}

for my $class (qw(DBIO::Firebird::Storage DBIO::Firebird::Storage::InterBase)) {
  is_deeply bulk($class, [ 1, '5.5', 'x' ], [ 2, undef, '' ]), [ [ 1, '5.5', 'x' ], [ 2, undef, '' ] ],
    "$class, populate: numbers pass";
  my $ok = eval { bulk($class, [ 1, 5, 'a' ], [ 2, '', 'b' ]); 1 };
  ok !$ok && $@ =~ /refus/i && $@ =~ /numeric column 'n'/,
    "$class, populate: '' for a numeric column is refused too";
  $ok = eval { bulk($class, [ 'x', 5, 'a' ]); 1 };
  ok !$ok && $@ =~ /numeric column 'id'/, "$class, populate: also in the first column";
}

done_testing;
