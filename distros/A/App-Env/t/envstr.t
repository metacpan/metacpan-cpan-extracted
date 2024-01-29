#!perl

use Test2::V0;
use Test::Lib;

use File::Which;

use File::Temp;
use App::Env;

## no critic ( InputOutput::ProhibitBackTickOperators)

plan skip_all => '"env" command not in path'
  unless defined which( 'env' );

my $app1 = App::Env->new( 'App1' );

{
    my ( $envstr, $output );
    # limit env string so it doesn't overflow shell buffer on some test
    # systems
    $envstr = $app1->str( qr/Site1_App1.*/ );

    $output = qx{env $envstr $^X -e 'print \$ENV{Site1_App1}'};
    die "error running env: $@\n" if $@;
    chomp $output;
    is( $output, '1', 'envstr' );
}

subtest 'illegal name' => sub {
    local $ENV{'BASH_FUNC_ml%%'} = 1;
    my $app = App::Env->new( 'Null' );
    ok( exists $app->{'BASH_FUNC_ml%%'}, 'set in environment' );
    unlike( $app->str, qr/BASH_FUNC_ml%%/, 'not in default envstr' );
    like( $app->str( { AllowIllegalVariableNames => 1 } ), qr/BASH_FUNC_ml%%/, 'force into envstr' );
};

sub test_exclude {

    my $ctx = context();

    my ( $exclude, $label ) = @_;

    my $envstr = $app1->str( { Exclude => $exclude } );

    my $output;
    ok( lives { $output = qx{env $envstr $^X -e 'print \$ENV{Site1_App1}'} }, 'grab environment' )
      or note $@;

    chomp $output;
    is( $output, q{}, $label );
    $ctx->release;
}

# test exclusion
test_exclude( qr/Site1_.*/,   'exclude: regexp' );
test_exclude( 'Site1_App1',   'exclude: scalar' );
test_exclude( ['Site1_App1'], 'exclude: array' );

test_exclude(
    sub {
        my ( $var ) = @_;
        return $var eq 'Site1_App1' ? 1 : 0;
    },
    'exclude: code',
);


# test for TERMCAP handling
SKIP: {
    skip q{no TERMCAP in environment; can't test for it}, 2
      unless exists $ENV{TERMCAP};

    ok( $app1->str()            !~ /\bTERMCAP\b/, 'TERMCAP handling' );
    ok( $app1->str( 'TERMCAP' ) =~ /\bTERMCAP\b/, 'TERMCAP handling' );
}

done_testing;
