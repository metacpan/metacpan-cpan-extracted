#! perl -w

use Test::Most;
use App::JESP;

# use Log::Any::Adapter qw/Stderr/;

if( $^O =~ /Win/ ){
    plan skip_all => 'No script test on windows please';
}

{
    # A home that is there.
    my $jesp = App::JESP->new({ dsn => 'dbi:SQLite:dbname=:memory:',
                                username => undef,
                                password => undef,
                                home => './t/homescripts/'
                            });
    ok( my $plan = $jesp->plan() );

    ok( my $patches = $plan->patches() );
    is( scalar( @{$patches} ) , 3 , "3 test patches");
    ok( ! $patches->[2]->sql() , "No sql in patch 5");
    ok( $patches->[2]->script_file(), "Patch 3 is a script" );
}

done_testing();
