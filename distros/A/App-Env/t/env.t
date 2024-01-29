#!perl

use Test2::V0;
use Test::Lib;

use File::Which;
use File::Temp;

use App::Env;

my $app1 = App::Env->new( 'App1' );


subtest 'context 1' => sub {
    my $env = $app1->env;
    ok( 'HASH' eq ref $env, 'type' );
    is( $env->{Site1_App1}, '1', 'value' );
};

subtest 'context 2' => sub {
    my $value = $app1->env( 'Site1_App1' );
    ok( !ref $value, 'type' );
    is( $value, 1, 'value' );

    ok( dies { $app1->env( 'Site1_App1', { Exclude => qr/Site.*/ } ) }, "can't use Exclude" );

};


subtest 'context 3' => sub {
    my @values = $app1->env( 'Site1_App1', 'NotExist', 'Site1_App1_v1' );
    ok( @values == 3, 'nelem' );
    is( \@values, [ 1, undef, 1 ], 'value' );

    ok(
        dies {
            @values = $app1->env( 'Site1_App1', 'NotExist', 'Site1_App1_v1', { Exclude => qr/v1$/ } );
        },
        'exclude prohibited',
    );
};

subtest 'context 4' => sub {

    subtest 'incude' => sub {
        my $env;
        ok( lives { $env = $app1->env( qr/Site1_App1.*/ ) } )
          or note $@;
        ok( 'HASH' eq ref $env, 'type' );
        is(
            $env,
            hash {
                field Site1_App1    => 1;
                field Site1_App1_v1 => 1;
                end;
            },
            'value',
        );
    };

    subtest 'exclude' => sub {
        my $env;
        ok( lives { $env = $app1->env( qr/Site1_App1.*/, { Exclude => qr/v1$/ } ) }, 'env' )
          or note $@;
        ok( 'HASH' eq ref $env, 'type' );
        is(
            $env,
            hash {
                field Site1_App1 => 1;
                end;
            },
            'value',
        );
    };

};

subtest 'illegal name' => sub {
    local $ENV{'BASH_FUNC_ml%%'} = 1;
    my $app = App::Env->new( 'Null' );
    is( $app->env( 'BASH_FUNC_ml%%' ), 1, 'default included' );
    is( $app->env( 'BASH_FUNC_ml%%', { AllowIllegalVariableNames => !!0 } ),
        U(), 'excluded via AllowIllegalVariablesNames' );
};


sub test_exclude {
    my $ctx = context;

    my ( $exclude, $expect, $label ) = @_;
    my $env;
    ok( lives { $env = $app1->env( qr/Site1_App1.*/, { Exclude => $exclude } ) } )
      or note $@;
    is( $env, $expect, $label );
    $ctx->release;
}

# what's left after the excludes below
my %subexp = ( Site1_App1_v1 => 1 );

# test exclusion
test_exclude( qr/Site1_.*/,    {},       'exclude: re, all' );
test_exclude( qr/Site1_App1$/, \%subexp, 'exclude: re, partial' );

test_exclude( 'Site1_App1', \%subexp, 'exclude: scalar' );

test_exclude( ['Site1_App1'], \%subexp, 'exclude: array of scalar' );

test_exclude(
    sub {
        my ( $var ) = @_;
        return $var eq 'Site1_App1' ? 1 : 0;
    },
    \%subexp,
    'exclude: code',
);


done_testing;
