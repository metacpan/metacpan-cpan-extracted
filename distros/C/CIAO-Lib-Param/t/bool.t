#! perl

use strict;
use warnings;

use Test2::V0;
use Test::TempDir::Tiny;
use File::Path;
use File::Spec::Functions 'rel2abs';
use CIAO::Lib::Param;

use constant PFILE => 'surface_intercept';
use constant PARAM => rel2abs( 'param' );

in_tempdir 'test' => sub {

    local $ENV{PFILES} = 'tmp;' . PARAM;

    mkdir( 'tmp', 0755 );

    my $pf;
    my $value;

    ok( lives { $pf = CIAO::Lib::Param->new( PFILE, 'rH' ) }, 'construct object' )
      or bail_out( $@ );

    # make sure boolean transformations in get() work like in getb()
    is( $pf->getb( 'onlygoodrays' ), T(), 'getb: true' );
    is( $pf->get( 'onlygoodrays' ),  T(), 'get boolean: true' );
    is( $pf->getb( 'help' ),         F(), 'getb: false' );
    is( $pf->get( 'help' ),          F(), 'get boolean: false' );


    # now try different ways of setting booleans. Since the parameter file
    # has been opened in non-prompt mode (H), we'll get croaks on error

    subtest 'boolean value' => sub {
        ok( dies { $pf->set( 'help', 'frob' ) }, 'bad string', );

        subtest 'yes' => sub {
            ok( lives { $pf->set( 'help', 'yes' ) }, 'set' );
            is( $pf->get( 'help' ), T(), 'test' );
        };

        subtest 'no' => sub {
            ok( lives { $pf->set( 'help', 'no' ); }, 'set' );
            is( $pf->get( 'help' ), F(), 'test' );
        };
    };


    subtest 'try boolean numerics to test automatic conversion' => sub {

        $pf->set( 'help', 'yes' );
        ok( lives { $pf->set( 'help', 0 ); } ) or bail_out( $@ );
        is( $pf->get( 'help' ), F(), 'set: 0' );

        $pf->set( 'help', 'no' );
        ok( lives { $pf->set( 'help', 1 ); } ) or bail_out( $@ );
        is( $pf->get( 'help' ), T(), 'set: 1' );

        $pf->set( 'help', 'yes' );
        ok(
            lives {
                no warnings;
                $pf->set( 'help', undef );
            } ) or bail_out( $@ );
        is( $pf->get( 'help' ), F(), 'set: undef' );
    };


    subtest 'Perl yes/no values are handled correctly' => sub {
        # these are used by the get method

        $pf->set( 'help', 0 );
        $value = $pf->get( 'help' );

        $pf->set( 'help', 1 );
        $pf->set( 'help', $value );

        is( $pf->get( 'help' ), F(), 'set: get(0)' );

        $pf->set( 'help', 1 );
        $value = $pf->get( 'help' );
        $pf->set( 'help', 0 );
        $pf->set( 'help', $value );
        is( $pf->get( 'help' ), T(), 'set: get(0)' );
    };
};

done_testing;
