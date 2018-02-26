use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use DBIDM_Test qw/die_ok sqlLike HR_connect $dbh/;

HR_connect;

use constant ORA_XMLTYPE => 108;
HR->Type(ORA_XML => 
  to_DB   => sub {$_[0] = [{dbd_attrs => { ora_type => ORA_XMLTYPE }}, $_[0]]},
);

HR->table('Employee')->metadm->define_column_type(ORA_XML => qw/xml1 xml2/);


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

done_testing;

