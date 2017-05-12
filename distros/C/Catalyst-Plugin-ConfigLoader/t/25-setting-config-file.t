use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

BEGIN {

    # Remove all relevant env variables to avoid accidental fail
    foreach my $name ( grep { m{^(CATALYST|MOCKAPP)} } keys %ENV ) {
        delete $ENV{ $name };
    }

    eval { require Catalyst; Catalyst->VERSION( '5.80001' ); };

    plan skip_all => 'Catalyst 5.80001 required' if $@;
    plan tests => 18;

    use Catalyst::Test ();

}

## TestApp1: a .conf config file exists but should not be loaded
{

    Catalyst::Test->import('TestApp1');

    note( "TestApp1" );

    ok my ( $res, $c ) = ctx_request( '/' ), 'context object';

    isa_ok( $c, "TestApp1" );

    subtest "normal config loaded" => sub {

        is( get( '/appconfig/foo' ), "bar1", "config var foo ok" );

        ## a config var not set will give a blank web page hence ""
        is( get( '/appconfig/bar' ), "", "config var in custom config" );

    };
    is( get( '/appconfig/bar' ), "", "custom config not loaded" );
}

## TestApp2: config points to a file in addition to normal config and
## should get loaded
{
    Catalyst::Test->import('TestApp2');

    note( "TestApp2" );

    ok my ( $res, $c ) = ctx_request( '/' ), 'context object';

    isa_ok( $c, "TestApp2" );

    subtest "normal config loaded" => sub {

        is( get( '/appconfig/foo' ), "bar2", "config var foo" );

        is( get( '/appconfig/unspecified_variable' ), "", "unknown config var" );

    };

    is( get( '/appconfig/bar' ), "baz2", "custom config loaded" );
}

## TestApp3: config points to a directory
{
    Catalyst::Test->import('TestApp3');

    note( "TestApp3" );

    ok my ( $res, $c ) = ctx_request( '/' ), 'context object';

    isa_ok( $c, "TestApp3" );

    subtest "normal config loaded" => sub {

        is( get( '/appconfig/foo' ), "bar3", "config var foo" );

        is( get( '/appconfig/unspecified_variable' ), "", "unknown config var" );

    };

    is( get( '/appconfig/test3_conf3' ), "a_value", "custom config var3 set" );
    is( get( '/appconfig/test3_conf4' ), "", "custom config var4 not set" );

}

## TestApp4: config points to a directory with a suffix
{
    Catalyst::Test->import('TestApp4');

    note( "TestApp4" );

    ok my ( $res, $c ) = ctx_request( '/' ), 'context object';

    isa_ok( $c, "TestApp4" );

    subtest "normal config loaded" => sub {

        is( get( '/appconfig/foo' ), "bar4", "config var foo" );

        is( get( '/appconfig/unspecified_variable' ), "", "unknown config var" );

    };

    is( get( '/appconfig/test4_conf3' ), "a_value", "custom config var3 set" );
    is( get( '/appconfig/test4_conf4' ), "", "custom config var4 not set" );

}
