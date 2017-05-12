#! perl -w

use Test::Most;
BEGIN{
    eval "use Test::PostgreSQL";
    plan skip_all => "Test::PostgreSQL is required for this test" if $@;
    eval "use Net::EmptyPort";
    plan skip_all => "Net::EmptyPort is required for this test" if $@;
}

use App::JESP;

my $pgsql = eval{ Test::PostgreSQL->new({ port => Net::EmptyPort::empty_port() }) } or plan skip_all => $@.' - '.$Test::PostgreSQL::errstr;

my $jesp = App::JESP->new({ dsn => $pgsql->dsn(),
                            password => '',
                            username => 'postgres',
                            home => './t/home_pgsql/'
                        });
throws_ok(sub{ $jesp->deploy() } , qr/ERROR querying meta/ );

# Time to install
$jesp->install();
# And deploy
is( $jesp->deploy(), 2, "Ok applied 2 patches");
is( $jesp->deploy(), 0, "Ok applied 0 patches on the second call");

# Now let's insert one country. This should work just fine.
{
    $jesp->dbix_simple()->insert('country', { country => 'Groland' });
    my $hashes = $jesp->dbix_simple()->select( 'country' , [ 'country' ] )->hashes();
    is( $hashes->[0]->{country} , 'Groland' );
}

# Now let's insert something that was defined at the very end of the last patch.
# this should also work just fine.
{
    $jesp->dbix_simple()->insert('somecrazytable', { id => 1 ,name => 'Phileston' });
    my $hashes = $jesp->dbix_simple()->select( 'somecrazytable' , [ 'name' ] )->hashes();
    is( $hashes->[0]->{name} , 'Phileston' );
}

done_testing();
