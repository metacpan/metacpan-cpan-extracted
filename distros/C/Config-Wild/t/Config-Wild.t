#!perl

use Test::More;
use Test::Fatal;

BEGIN { use_ok( 'Config::Wild' ) }

my $data_dir = 't/data/cfgs';

subtest autoload => sub {

    my $cfg = Config::Wild->new( "$data_dir/test.cnf" );

    is( $cfg->foo, 'ok', 'autoload' );
};

subtest blanks => sub {

    my $cfg = Config::Wild->new( "$data_dir/blanks.cnf" );

    is( $cfg->get( 'foo' ), 'bar',  'trailing blanks' );
    is( $cfg->get( 'too' ), 'good', 'leading blanks' );

};

subtest variables => sub {

    my $cfg = Config::Wild->new( "$data_dir/vars.cnf" );

    is( $cfg->get( 'twig' ), 'here/there', 'internal vars' );

    local $ENV{CWTEST} = 'not now';

    is( $cfg->get( 'entvar' ), 'not now or then', 'env vars' );

    is( $cfg->get( 'bothvarenv' ), 'not now or where', 'both vars (env)' );

    is( $cfg->get( 'bothvarint' ), 'here or not', 'both vars (internal)' );

    is( $cfg->get( 'nest3' ), '0/1/2/3', 'nested internal' );

    is( $cfg->get( 'enest2' ), 'not now/or then/or how',
        'nested internal/env' );

    done_testing;


};

subtest non_existent_expanded_variables => sub {

    my $cfg = Config::Wild->new( "$data_dir/vars.cnf" );

    is( $cfg->get( 'entvar' ), ' or then', 'missing environment variable' );

    $cfg->delete( 'root' );

    is( $cfg->get( 'twig' ), '/there', 'missing Config::Wild variable' );

    done_testing;
};

subtest wildcard => sub {

    my $cfg = Config::Wild->new( "$data_dir/wildcard.cnf" );

    is( $cfg->get( 'goo_1' ),   1234, 'wildcard 1' );
    is( $cfg->get( 'foo_cas' ), 5678, 'wildcard 2' );

    done_testing;

};

subtest expand_wildcard => sub {

    my $cfg
      = Config::Wild->new( "$data_dir/wildcard.cnf", { ExpandWild => 1 } );

    is( $cfg->get( 'rfoo_1' ), 'foo1', 'expand wildcard w/ abs override' );
    is( $cfg->get( 'rfoo_2' ), 5678,   'expand wildcard w/ no override' );

    is( $cfg->get( 'rfoo_e' ), '/foo', 'expand non-existent var' );

    done_testing;

};

subtest boolean => sub {

    my $cfg = Config::Wild->new( "$data_dir/boolean.cnf" );

    is( $cfg->getbool( 'foo' ), 1, 'yes' );
    is( $cfg->getbool( 'goo' ), 0, 'no' );

    is( $cfg->getbool( 'bar' ), 1, 'on' );
    is( $cfg->getbool( 'baz' ), 0, 'off' );

    is( $cfg->getbool( 'que' ), 1, 'A 1' );
    is( $cfg->getbool( 'qot' ), 0, 'A 0' );

    is( $cfg->getbool( 'flurb' ), undef, 'non-boolean' );

};


subtest 'dir+path' => sub {

    like(
        exception { Config::Wild->new( { dir => '.', path => ['.'] } ) },
        qr/options dir and path may not/,
        "dir + path may not be combined"
    );


};


done_testing;
