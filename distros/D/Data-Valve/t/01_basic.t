use strict;
use Test::More (tests => 32);

BEGIN
{
    use_ok("Data::Valve");
}

{
    my $valve = Data::Valve->new(
        max_items => 5,
        interval  => 3
    );

    # 5 items should succeed
    for( 1.. 5) {
        ok( $valve->try_push(), "try $_ should succeed" );
    }

    ok( ! $valve->try_push(), "this try should fail" );

    diag("sleeping for 3 seconds...");
    sleep 3;

    ok( $valve->try_push(), "try after 3 seconds should work");
}

{
    my $valve = Data::Valve->new(
        max_items => 5,
        interval  => 3
    );

    # 5 items should succeed
    for( 1.. 5) {
        ok( $valve->try_push(), "try $_ should succeed" );
    }

    ok( ! $valve->try_push(), "this try should fail" );
    $valve->reset();

    for( 1.. 5) {
        ok( $valve->try_push(), "try $_ should succeed" );
    }
}

{
    my $valve = Data::Valve->new(
        max_items => 5,
        interval  => 3
    );

    $valve->fill();
    ok( ! $valve->try_push(), "this try should fail" );
}

{
    my $valve = Data::Valve->new(
        max_items => 5,
        interval  => 3
    );

    # 5 items should succeed
    for( 1.. 5) {
        ok( $valve->try_push(key => "foo"), "try $_ should succeed" );
    }

    ok( ! $valve->try_push(key => "foo"), "this try should fail" );
    ok( $valve->try_push(key => "bar"), "this try should succeed" );

    diag("sleeping for 3 seconds...");
    sleep 3;

    ok( $valve->try_push(key => "foo"), "try after 3 seconds should work");
}

{
    my $valve = Data::Valve->new(
        max_items => 5,
        interval  => 3,
        strict_interval => 1,
    );

    ok(  $valve->try_push(key => "foo"), "try 1 should succeed" );
    ok(! $valve->try_push(key => "foo"), "try 2 should fail" );
    diag("sleeping for 3 seconds...");
    sleep 3;
    ok(  $valve->try_push(key => "foo"), "try 3 should succeed" );
    ok(! $valve->try_push(key => "foo"), "try 4 should fail" );
}
