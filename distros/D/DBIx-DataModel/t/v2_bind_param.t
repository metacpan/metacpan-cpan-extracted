use strict;
use warnings;

use SQL::Abstract::Test import => [qw/is_same_sql_bind/];
use SQL::Abstract::More;

use DBIx::DataModel -compatibility=> undef;

use constant NTESTS  => 5;
use Test::More tests => NTESTS;


DBIx::DataModel->Schema('HR') # Human Resources
->Table(Employee   => T_Employee   => qw/emp_id/);

use constant ORA_XMLTYPE => 108;
HR->Type(ORA_XML => 
  to_DB   => sub {$_[0] = [{dbd_attrs => { ora_type => ORA_XMLTYPE }}, $_[0]]},
);

HR->table('Employee')->metadm->define_column_type(ORA_XML => qw/xml1 xml2/);

SKIP: {
  eval "use DBD::Mock 1.36; 1"
    or skip "DBD::Mock 1.36 does not seem to be installed", NTESTS;

  {
    # DIRTY HACK: remote surgery into DBD::Mock::st to compensate for the
    # missing support for ternary form of bind_param().
    # (see L<https://rt.cpan.org/Public/Bug/Display.html?id=84495>).
    require DBD::Mock::st;
    no warnings 'redefine';
    my $orig = \&DBD::Mock::st::bind_param;
    *DBD::Mock::st::bind_param = sub {
      my ( $sth, $param_num, $val, $attr ) = @_;
      $val = [$val, $attr] if $attr;
      return $sth->$orig($param_num, $val);
    };
  }

  my $dbh = DBI->connect('DBI:Mock:', '', '', 
                         {RaiseError => 1, AutoCommit => 1});
  HR->dbh($dbh);

  sub sqlLike { # closure on $dbh
                # TODO : fix line number, should report the caller's line
    my $msg = pop @_;

    for (my $hist_index = -(@_ / 2); $hist_index < 0; $hist_index++) {
      my ($sql, $bind)  = (shift, shift);
      my $hist = $dbh->{mock_all_history}[$hist_index];

      is_same_sql_bind($hist->statement, $hist->bound_params,
                       $sql,             $bind, "$msg [$hist_index]");
    }
    $dbh->{mock_clear_history} = 1;
  }

  # manual bind_param (using named placeholder)
  my $stmt = HR->table('Employee')->select(
    -where     => {foo => '?:p1'},
    -result_as => 'statement',
   );
  $stmt->bind(p1 => 123, {ora_type => 999});
  $stmt->execute;
  sqlLike("SELECT * FROM T_Employee WHERE foo = ?",
          [[123, {ora_type => 999}]],
          "ternary form of bind_param");


  # passing the SQL type directly in the call
  my $rows = HR->table('Employee')->select(
    -where     => {foo => [{dbd_attrs => {ora_type => 999}}, 123]},
   );
  sqlLike("SELECT * FROM T_Employee WHERE foo = ?",
          [[123, {ora_type => 999}]],
          "SQL type directly in select() data");

  # insert with manual SQL type
  HR->table('Employee')->insert(
    {foo => [{dbd_attrs => {ora_type => 999}}, 123]}
   );
  sqlLike("INSERT INTO T_Employee(foo) VALUES (?)",
          [[123, {ora_type => 999}]],
          "insert with type info");

  # update with manual SQL type
  HR->table('Employee')->update(
    {emp_id => 111, foo => [{dbd_attrs => {ora_type => 999}}, 123]}
   );
  sqlLike("UPDATE T_Employee SET foo = ? WHERE emp_id = ?",
          [[123, {ora_type => 999}], 111],
          "update with type info");


  # insert with automatic SQL type from DBIDM column type
  HR->table('Employee')->insert(
    {xml1 => '<xml></xml>'},
   );
  sqlLike("INSERT INTO T_Employee(xml1) VALUES (?)",
          [['<xml></xml>', {ora_type => ORA_XMLTYPE}]],
          "insert with automatic SQL type from DBIDM column type");
}
