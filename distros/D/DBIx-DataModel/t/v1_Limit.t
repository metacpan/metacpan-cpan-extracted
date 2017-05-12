use strict;
use warnings;

use DBI;
use SQL::Abstract::Test import => [qw/is_same_sql_bind/];
use SQL::Abstract::More;
use constant N_DBI_MOCK_TESTS => 9;
use constant N_BASIC_TESTS    => 1;

use Test::More tests => (N_BASIC_TESTS + N_DBI_MOCK_TESTS);

use_ok("DBIx::DataModel", -compatibility=> 1.0);

SKIP: {
  eval "use DBD::Mock 1.36; 1"
    or skip "DBD::Mock 1.36 does not seem to be installed", N_DBI_MOCK_TESTS;

  my $dbh = DBI->connect('DBI:Mock:', '', '', {RaiseError => 1});
  sub sqlLike { # closure on $dbh
    my $msg = pop @_;    

    for (my $hist_index = -(@_ / 2); $hist_index < 0; $hist_index++) {
      my ($sql, $bind)  = (shift, shift);
      my $hist = $dbh->{mock_all_history}[$hist_index];

      is_same_sql_bind($hist->statement, $hist->bound_params,
                       $sql,             $bind, "$msg [$hist_index]");
    }
    $dbh->{mock_clear_history} = 1;
  }

  my $stmt;
  DBIx::DataModel->Schema('D1', sqlDialect => {limitOffset => "LimitOffset"})
                 ->Table(qw/T T PK/)
                 ->dbh($dbh);
  $stmt = D1::T->select(-limit => 13, -result_as => 'statement');
  $stmt->all;
  sqlLike('SELECT * FROM T LIMIT ? OFFSET ?', [13, 0], 'limitOffset');

  $stmt->row_count;
  sqlLike('SELECT COUNT(*) FROM T', [], 'count(*) limitOffset');

  DBIx::DataModel->Schema('D2', sqlDialect => 'MySQL')
                 ->Table(qw/T T PK/)
                 ->dbh($dbh);
  $stmt = D2::T->select(-columns => [qw/foo bar/],
                        -limit => 13,
                        -result_as => 'statement');
  $stmt->all;
  sqlLike('SELECT foo, bar FROM T LIMIT ?, ?', [0, 13], 'limitXY');

  $stmt->row_count;
  sqlLike('SELECT COUNT(*) FROM T', [], 'count(*) limitXY');

  DBIx::DataModel->Schema('D3', sqlDialect => {limitOffset => "LimitYX"})
                 ->Table(qw/T T PK/)
                 ->dbh($dbh);
  $stmt = D3::T->select(
    -where => {foo => 999},
    -limit => 13,
    -offset => 7,
    -result_as => 'statement');
  $stmt->all;
  sqlLike('SELECT * FROM T WHERE foo = ? LIMIT ?, ?', [999, 13, 7], 'limitYX');

  $stmt->row_count;
  sqlLike('SELECT COUNT(*) FROM T  WHERE foo = ?', [999], 'count(*) limitYX');


  my $sqlam = SQL::Abstract::More->new(sql_dialect =>  "Oracle");
  D3->singleton->sql_abstract($sqlam);
  $stmt = D3::T->select(
    -where => {foo => 999},
    -limit => 13,
    -offset => 7,
    -result_as => 'statement');
  $stmt->sqlize;
  my ($sql, @bind) = $stmt->sql;
  like($sql, qr/ROWNUM/, 'limit Oracle');

  $stmt->row_count;
  sqlLike('SELECT COUNT(*) FROM T  WHERE foo = ?', [999], 'count(*) limit Oracle');

  $stmt = D3::T->select(
    -columns   => [-distinct => qw/foo bar/],
    -result_as => 'statement',
   );

  $stmt->row_count;
  sqlLike('SELECT COUNT(*) FROM (SELECT DISTINCT foo, bar FROM T) count_wrapper',
          [],
          'count DISTINCT');
}



