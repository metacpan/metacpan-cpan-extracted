#! perl -w

use strict;
use warnings;
use Test::Most;
use App::JESP;

# Test deployment in SQLite

# use Log::Any::Adapter qw/Stderr/;

# A home that is there.
my $jesp = App::JESP->new({ dsn => 'dbi:SQLite:dbname=:memory:',
                            username => undef,
                            password => undef,
                            home => './t/home/'
                        });
throws_ok(sub{ $jesp->deploy() } , qr/ERROR querying meta/ );

# Time to install
$jesp->install();
 my $status = $jesp->status();
is( scalar( @{$status->{plan_patches}} ) , 4, "Ok 4 patches in plan");
is( $jesp->deploy(), 4, "Ok applied 4 patches");

$status = $jesp->status();
is( scalar( @{$status->{plan_patches}} ) , 4, "Ok 4 patches in plan");
map{ ok( $_->applied_datetime() )  } @{$status->{plan_patches}};
is( scalar( @{$status->{plan_orphans}} ) , 0 , "Ok 0 orphans");


is( $jesp->deploy(), 0, "Ok applied 0 patches on the second call");

# After this is installed, we should be able to use and query the
# table foobar with all its columns.
{
    $jesp->dbix_simple()->insert('foobar', {bla => 'some' , baz => 'thing' });
    my @rows = @{ $jesp->dbix_simple()->select( 'foobar' , [ 'id', 'bla', 'baz' ] )->hashes() };
    is( scalar( @rows ) , 2 );
}

# Now we want to force the application of the patch 'insert_one_foobar'
is( $jesp->deploy({ force => 1, patches => [ 'insert_one_foobar' ] }) , 1 , "Only one patch forced applied");
{
    my @rows = @{ $jesp->dbix_simple()->select( 'foobar' , [ 'id', 'bla', 'baz' ] )->hashes() };
    is( scalar( @rows ) , 3, "The forced patch created another foobar row");
}

# Force logonly to refresh all the meta table, without effectively doing anything.
is( $jesp->deploy({ force => 1, logonly => 1  }) , 4 , "Ok 4  patches forced applied, only logging");
{
    my @rows = @{ $jesp->dbix_simple()->select( 'foobar' , [ 'id', 'bla', 'baz' ] )->hashes() };
    is( scalar( @rows ) , 3, "Still 3 items in foobar");
}

# And also do clever stuff with the customer table and the customer_address view
{
    $jesp->dbix_simple()->insert('customer', { cust_id => 123 , cust_name => 'Armand' , cust_addr => 'Rue de la mouffette' });
    {
        my $hashes = $jesp->dbix_simple()->select( 'customer_address' , [ 'cust_id', 'cust_addr' ] )->hashes();
        is( $hashes->[0]->{cust_addr} , 'Rue de la mouffette' );
    }
    {
        $jesp->dbix_simple()->update( 'customer_address', { cust_addr => 'Rue de la pierre en bois' } ,{ cust_id => 123 } );
        my $hashes = $jesp->dbix_simple()->select( 'customer' , [ 'cust_id', 'cust_addr' ] )->hashes();
        is( $hashes->[0]->{cust_addr} , 'Rue de la pierre en bois' , "The trigger did work!" );
    }
}

{
    # Create some orphans and check we have the right amount of orphans.
    shift @{$jesp->plan()->patches()};
    my $status = $jesp->status();
    is( scalar( @{$status->{plan_patches}} ) , 3, "Ok 3 patches in plan");
    is( scalar( @{$status->{plan_orphans}} ) , 1 , "Ok 1 orphan");
}

done_testing();
