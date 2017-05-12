use Test::More;
BEGIN: {
    my @missing = ();
    eval "use Catalyst::Model::CDBI";
    push @missing, "Catalyst::Model::CDBI" if $@;
    eval "use Class::DBI::SQLite";
    push @missing, "Class::DBI::SQLite" if $@;
    eval "use YAML";
    push @missing, "YAML" if $@;
    if ( @missing ) {
        plan skip_all => "The following are required to run the test app: " .
                         join(', ', @missing);
    }
    else {
        plan tests => 22;
        require Catalyst::Test; import Catalyst::Test 'MyApp';
    }
}
use lib 't/MyApp/lib';

# add (complete, no transaction)
ok( request('http://localhost/cd/add/Band1/CD1/1/Notes1'), 'Record 1' );
ok( request('http://localhost/cd/add/Band2/CD2/2/Notes2'), 'Record 2' );
ok( request('http://localhost/cd/add/Band3/CD3/3/Notes3'), 'Record 3' );
ok( request('http://localhost/cd/add/Band4/CD4/4/Notes4'), 'Record 4' );
ok( request('http://localhost/cd/add/Band5/CD5/5/Notes5'), 'Record 5' );

# add_error (incomplete, no transaction.  Should leave a missing liner_notes)
ok( request('http://localhost/cd/add_error/Incomplete%20Band%201/Incomplete%20CD%201/1/Incomplete%20Notes1'), 'Incomplete (add_error) Record 1' );

# add_atomic (complete, inside transaction)
# also test to make sure $c->atomic() is an alias to $c->transaction()
ok( request('http://localhost/cd/add_atomic/Band1/Atomic%20CD1/1/Atomic%20Notes1'), 'Atomic Record 1' );
ok( request('http://localhost/cd/add_atomic/Band2/Atomic%20CD2/2/Atomic%20Notes2'), 'Atomic Record 2' );
ok( request('http://localhost/cd/add_atomic/Band3/Atomic%20CD3/3/Atomic%20Notes3'), 'Atomic Record 3' );
ok( request('http://localhost/cd/add_transaction/Band4/Atomic%20CD4/4/Atomic%20Notes4'), 'Atomic Record 4, using $c->transaction()' );
ok( request('http://localhost/cd/add_trans/Band5/Atomic%20CD5/5/Atomic%20Notes5'), 'Atomic Record 5, using $c->trans()' );

# add_error (incomplete, no transaction.  Should leave a missing liner_notes)
ok( request('http://localhost/cd/add_error/Incomplete%20Band%202/Incomplete%20CD%202/2/Incomplete%20Notes2'), 'Incomplete (add_error) Record 2' );
ok( request('http://localhost/cd/add_error/Incomplete%20Band%203/Incomplete%20CD%203/3/Incomplete%20Notes3'), 'Incomplete (add_error) Record 3' );

# add_error_atomic (incomplete, inside transaction.  Should be rolled back
# and nothing here should show up in any of the tables.)
ok( request('http://localhost/cd/add_error_atomic/Band6/Atomic%20CD6/6/Atomic%20Notes6'), 'Atomic Record 6' );
ok( request('http://localhost/cd/add_error_atomic/Band7/Atomic%20CD7/7/Atomic%20Notes7'), 'Atomic Record 7' );
ok( request('http://localhost/cd/add_error_atomic/Band8/Atomic%20CD8/8/Atomic%20Notes8'), 'Atomic Record 8' );
ok( request('http://localhost/cd/add_error_transaction/Band9/Atomic%20CD9/9/Atomic%20Notes9'), 'Atomic Record 9, using $c->transaction()' );
ok( request('http://localhost/cd/add_error_trans/Band10/Atomic%20CD10/10/Atomic%20Notes10'), 'Atomic Record 10, using $c->trans()' );

# add (complete, no transaction)
ok( request('http://localhost/cd/add/Band11/CD11/11/Notes11'), 'Record 11' );

# Now that we're done adding records, some with more success than others, our
# tables should look like this:
{
    my $artist = get('http://localhost/artist/');
    my $wanted = <<END;
artistid|name
1|Band1
2|Band2
3|Band3
4|Band4
5|Band5
6|Incomplete Band 1
7|Incomplete Band 2
8|Incomplete Band 3
9|Band11
END
    cmp_ok( $artist, 'eq', $wanted, 'Check output of artist table' );
}
{
    my $cd = get('http://localhost/cd/');
    my $wanted = <<END;
cdid|artist|title|year
1|1|CD1|1
2|2|CD2|2
3|3|CD3|3
4|4|CD4|4
5|5|CD5|5
6|6|Incomplete CD 1|1
7|1|Atomic CD1|1
8|2|Atomic CD2|2
9|3|Atomic CD3|3
10|4|Atomic CD4|4
11|5|Atomic CD5|5
12|7|Incomplete CD 2|2
13|8|Incomplete CD 3|3
14|9|CD11|11
END
    cmp_ok( $cd, 'eq', $wanted, 'Check output of cd table' );
}
{
    my $linernotes = get('http://localhost/linernotes/');
    my $wanted = <<END;
cdid|notes
1|Notes1
2|Notes2
3|Notes3
4|Notes4
5|Notes5
7|Atomic Notes1
8|Atomic Notes2
9|Atomic Notes3
10|Atomic Notes4
11|Atomic Notes5
14|Notes11
END
    cmp_ok( $linernotes, 'eq', $wanted, 'Check output of liner_notes table' );
}
