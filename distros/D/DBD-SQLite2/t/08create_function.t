use Test::More;
BEGIN { plan tests => 20 }
use DBI;

sub now {
    return time();
}

sub add2 {
    my ( $a, $b ) = @_;

    return $a + $b;
}

sub my_sum {
    my $sum = 0;
    foreach my $x (@_) {
        $sum += $x;
    }
    return $sum;
}

sub error {
    die "function is dying: ", @_, "\n";
}

sub void_return {
}

sub return2 {
        return ( 1, 2 );
}

sub return_null {
        return undef;
}

sub my_defined {
        return defined $_[0];
}

sub noop {
        return $_[0];
}

my $dbh = DBI->connect("dbi:SQLite2:dbname=foo", "", "", { PrintError => 0 } );
ok($dbh);

$dbh->func( "now", 0, \&now, "create_function" );
my $result = $dbh->selectrow_arrayref( "SELECT now()" );

ok( $result->[0] );

$dbh->do( 'CREATE TEMP TABLE func_test ( a, b )' );
$dbh->do( 'INSERT INTO func_test VALUES ( 1, 3 )' );
$dbh->do( 'INSERT INTO func_test VALUES ( 0, 4 )' );

$dbh->func( "add2", 2, \&add2, "create_function" );
$result = $dbh->selectrow_arrayref( "SELECT add2(1,3)" );
ok( $result->[0] == 4 );

$result = $dbh->selectall_arrayref( "SELECT add2(a,b) FROM func_test" );
ok( $result->[0][0] = 4  && $result->[1][0] == 4 );

$dbh->func( "my_sum", -1, \&my_sum, "create_function" );
$result = $dbh->selectrow_arrayref( "SELECT my_sum( '2', 3, 4, '5')" );
ok( $result->[0] == 14 );

$dbh->func( "error", -1, \&error, "create_function" );
$result = $dbh->selectrow_arrayref( "SELECT error( 'I died' )" );
ok( !$result );
ok( $DBI::errstr =~ /function is dying: I died/ );

$dbh->func( "void_return", -1, \&void_return, "create_function" );
$result = $dbh->selectrow_arrayref( "SELECT void_return( 'I died' )" );
ok( $result && !defined $result->[0] );

$dbh->func( "return_null", -1, \&return_null, "create_function" );
$result = $dbh->selectrow_arrayref( "SELECT return_null()" );
ok( $result && !defined $result->[0] );

$dbh->func( "return2", -1, \&return2, "create_function" );
$result = $dbh->selectrow_arrayref( "SELECT return2()" );
ok( $result &&  $result->[0] == 2 );

$dbh->func( "my_defined", 1, \&my_defined, "create_function" );
$result = $dbh->selectrow_arrayref( "SELECT my_defined(1)" );
ok( $result &&  $result->[0] );

$result = $dbh->selectrow_arrayref( "SELECT my_defined('')" );
ok( $result &&  $result->[0] );

$result = $dbh->selectrow_arrayref( "SELECT my_defined('abc')" );
ok( $result &&  $result->[0] );

$result = $dbh->selectrow_arrayref( "SELECT my_defined(NULL)" );
ok( $result &&  !$result->[0] );

$dbh->func( "noop", 1, \&noop, "create_function" );
$result = $dbh->selectrow_arrayref( "SELECT noop(NULL)" );
ok( $result &&  !defined $result->[0] );

$result = $dbh->selectrow_arrayref( "SELECT noop(1)" );
ok( $result &&  $result->[0] == 1);

$result = $dbh->selectrow_arrayref( "SELECT noop('')" );
ok( $result &&  $result->[0] eq '' );

$result = $dbh->selectrow_arrayref( "SELECT noop(1.1)" );
ok( $result &&  $result->[0] == 1.1 );

#TODO: {
  #local $TODO = 'int overflow < 5.8.9 [RT #28448]'
  #  if $] < 5.008009 and $Config{use64bitint};
  use Config;
  sub return_big {
    return 2**32;
  }
  $dbh->func( "bignumber", 0, \&return_big, "create_function" );
  $result = $dbh->selectrow_arrayref( "SELECT bignumber()" );
  # sqlite_set_result_int cannot handle long, 4294967296
  ok ($result && $$result[0] > 0, "bignumber")
    or diag "$result, $$result[0] use64bitint=$Config{use64bitint} use64bitall=$Config{use64bitall}";
#}

sub return_double {
  return 3.0 / 2.0;
}
$dbh->func( "number3by2", 0, \&return_double, "create_function" );
$result = $dbh->selectrow_arrayref( "SELECT number3by2()" );
ok ($result && $$result[0] == 1.5, "number3by2");

$dbh->disconnect;
