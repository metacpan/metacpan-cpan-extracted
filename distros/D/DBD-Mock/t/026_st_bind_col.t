use 5.006;

use strict;
use warnings;

use Test::More tests => 12;

BEGIN {
    use_ok('DBD::Mock');
    use_ok('DBI');
}

my $dbh = DBI->connect( 'DBI:Mock:', '', '' );

$dbh->{mock_add_resultset} = [
                              [ 'id', 'type', 'inventory_id' ],
                              [ '1',  'european', '42' ],
                              [ '27', 'african',  '2' ],
                             ];

my $sth = $dbh->prepare( 'SELECT id, type, inventory_id FROM Swallow' );

$sth->execute();

{
    my ($id, $type, $inventory_id);

    $sth->bind_col( 1, \$id );
    $sth->bind_col( 2, \$type );
    $sth->bind_col( 3, \$inventory_id );

    ok( $sth->fetch(), 'fetch() returned data' );
    is( $id, 1, 'bind_col to $id == 1' );
    is( $type, 'european', 'bind_col to $type == "european"' );
    is( $inventory_id, 42, 'bind_col to $inventory_id == 42' );
}

{
    my %hash;

    $sth->bind_columns( \( @hash{ qw( id type inventory_id ) } ) );

    ok( $sth->fetch(), 'fetch() returned data' );
    is( $hash{id}, 27, 'bind_columns with hash, id == 1' );
    is( $hash{type}, 'african', 'bind_columns with hash, type == "african"' );
    is( $hash{inventory_id}, 2, 'bind_columns with hash, inventory_id == 2' );
}

{
    ok( ! $sth->fetchrow_arrayref(),
        'fetchrow_arrayref returns false after data is exhausted, even with bound columns' );
}

{
    $dbh->{mock_clear_history} = 1;

    my @rows =
        ( [ '1',  'european', '42' ],
          [ '27', 'african',  '2' ],
        );

    $dbh->{mock_add_resultset} = [
                                  [ 'id', 'type', 'inventory_id' ],
                                  @rows,
                                 ];

    my $results = $dbh->selectall_arrayref( 'SELECT id, type, inventory_id FROM Swallow' );

    is_deeply( $results,
               \@rows,
               'bind_col implementation does not break selectall_* methods' );
}

