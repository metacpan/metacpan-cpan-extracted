use strict;

use Test::More tests => 43;

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');
}

#use Data::Dumper qw( Dumper );

my @rs_foo = (
    [ 'this', 'that' ],
    [ 'this_one', 'that_one' ],
    [ 'this_two', 'that_two' ],
);
my $foo_sql = 'SELECT this, that FROM foo';

my @rs_login = (
    [ 'login', 'first_name', 'last_name' ],
    [ 'cwinters', 'Chris', 'Winters' ],
    [ 'bflay', 'Bobby', 'Flay' ],
    [ 'alincoln', 'Abe', 'Lincoln' ],
);
my $login_sql = 'SELECT login, first_name, last_name FROM foo';

my $dbh = DBI->connect( 'DBI:Mock:', '', '' );

# Seed the handle with two resultsets

# the first one ordered
$dbh->{mock_add_resultset} = [ @rs_foo ];

# the second one named
$dbh->{mock_add_resultset} = { sql     => $login_sql,
                               results => \@rs_login };

# run the first one
{
    my ( $sth );
    eval {
        $sth = $dbh->prepare( $foo_sql );
        $sth->execute();
    };
    check_resultset( $sth, [ @rs_foo ] );
}

{
    my ( $sth );
    eval {
        $sth = $dbh->prepare( $login_sql );
        $sth->execute();
    };
    check_resultset( $sth, [ @rs_login ] );
}

{
    my ( $sth );
    eval {
        $sth = $dbh->prepare( q{INSERT INTO foo VALUES ( 'Don Corleone' )} );
        $sth->execute();
    };
     ok( ! $sth->{Active},
        '...this should not be an active handle' );
}

sub check_resultset {
    my ( $sth, $check ) = @_;
    my $fields  = shift @{ $check };
    is( $sth->{mock_num_records}, scalar @{ $check },
        'Correct number of records reported by statement' );
    is( $sth->{mock_num_rows}, scalar @{ $check },
        'Correct number of rows reported by statement' );        
    is( $sth->rows, scalar @{ $check },
        'Correct number of rows reported by statement' );        
    is( $sth->{mock_current_record_num}, 0,
        'Current record number correct before fetching' );
    ok( $sth->{Active},
        '... this should be an active handle' );
    for ( my $i = 0; $i < scalar @{ $check }; $i++ ) {
        my $rec_num = $i + 1;
        my $this_check = $check->[$i];
        my $this_rec = $sth->fetchrow_arrayref;
        my $num_fields = scalar @{ $this_check };
        is( scalar @{ $this_rec }, $num_fields,
            "Record $rec_num, correct number of fields ($num_fields)" );
        for ( my $j = 0; $j <  $num_fields; $j++ ) {
            my $field_num = $j + 1;
            is( $this_rec->[$j], $this_check->[$j],
                "Record $rec_num, field $field_num" );
        }
        is( $sth->{mock_current_record_num}, $rec_num,
            "Record $rec_num, current record number tracked" );
        if ( $rec_num == scalar @{ $check } ) {
            ok( $sth->{mock_is_depleted},
                'Resultset depleted properly' );
            ok( ! $sth->{Active},
                '...this should not be an active handle anymore' );
        }
        else {
            ok( ! $sth->{mock_is_depleted},
                'Resultset not yet depleted' );
        }
    }

}
