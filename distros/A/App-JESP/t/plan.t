#! perl -w

use Test::Most;
use App::JESP;

# use Log::Any::Adapter qw/Stderr/;

{
    # A home that is not there.
    my $jesp = App::JESP->new({ dsn => 'dbi:SQLite:dbname=:memory:',
                                username => undef,
                                password => undef,
                                home => 'bla'
                            });
    throws_ok(sub{ my $plan = $jesp->plan() } , qr/does not exists/ );
}

{
    # A home that is there.
    my $jesp = App::JESP->new({ dsn => 'dbi:SQLite:dbname=:memory:',
                                username => undef,
                                password => undef,
                                home => './t/home/'
                            });
    ok( my $plan = $jesp->plan() );

    ok( my $patches = $plan->patches() );
    is( scalar( @{$patches} ) , 4 , "4 test patches");
    foreach my $patch ( @{$patches} ){
        ok( $patch->sql() , "Ok got SQL" );
    }
}

done_testing();
