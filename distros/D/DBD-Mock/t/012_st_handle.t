use strict;

use Test::More tests => 15;

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');  
}

# test misc. attributes

{
    my $dbh = DBI->connect('DBI:Mock:', 'user', 'pass');
    isa_ok($dbh, 'DBI::db'); 
    
    $dbh->{mock_add_resultset} = [[ 'Foo', 'Bar', 'Baz' ],[ 1, 1, 1 ]];

    my $sth = eval { $dbh->prepare('SELECT Foo, Bar, Baz FROM FooBarBaz') };
    ok(!$@, '... $sth handle prepared ok');
    isa_ok($sth, 'DBI::st');

    is($sth->{Statement}, 'SELECT Foo, Bar, Baz FROM FooBarBaz', '... got the right statement');
    is($sth->{Database}, $dbh, '... got the right Database handle');

    is($sth->{NUM_OF_FIELDS}, 3, '... got the right number of fields');
    is($sth->{NUM_OF_PARAMS}, 0, '... got the right number of params');    

    is_deeply(
        $sth->{NAME},
        [ 'Foo', 'Bar', 'Baz' ],
        '... got the right NAME attributes');

    is_deeply(
        $sth->{NAME_lc},
        [ 'foo', 'bar', 'baz' ],
        '... got the right NAME_lc attributes');

    is_deeply(
        $sth->{NAME_uc},
        [ 'FOO', 'BAR', 'BAZ' ],
        '... got the right NAME_uc attributes');    
            
    is_deeply(
        $sth->{NAME_hash},
        { Foo => 0, Bar => 1, Baz => 2 },
        '... got the right NAME_hash attributes');
        
    is_deeply(
        $sth->{NAME_hash_lc},
        { foo => 0, bar => 1, baz => 2 },
        '... got the right NAME_hash_lc attributes');
        
    is_deeply(
        $sth->{NAME_hash_uc},
        { FOO => 0, BAR => 1, BAZ => 2 },
        '... got the right NAME_hash_uc attributes');                    
}
