use strict;
use warnings;

use Test::More;

# test style cribbed from t/013_st_execute_bound_params.t

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');
}

my $sql = 'INSERT INTO staff (first_name, last_name, dept) VALUES(?, ?, ?)';

{
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    my $sth = eval { $dbh->prepare( $sql ) };

    # taken from: https://metacpan.org/module/DBI#Statement-Handle-Methods
    $dbh->{RaiseError} = 1;        # save having to check each method call
    $sth = $dbh->prepare($sql);

    $sth->bind_param_array(1, [ 'John', 'Mary', 'Tim' ]);
    $sth->bind_param_array(2, [ 'Booth', 'Todd', 'Robinson' ]);
    # TODO: $sth->bind_param_array(3, "SALES"); # scalar will be reused for each row

    eval {
        $sth->execute_array( { ArrayTupleStatus => \my @tuple_status } );
    };
    ok( ! $@, 'Called execute_array() ok' )
        or diag $@;
}

done_testing;
