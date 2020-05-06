#!perl

use Test2::V0;
use Test::Lib;

use Env::Path;

use File::Temp;
use App::Env;

plan skip_all => "'env' command not in path"
  unless Env::Path->PATH->Whence( 'env' );

my $app1 = App::Env->new( 'App1' );

my ( $envstr, $output );

# limit env string so it doesn't overflow shell buffer on some test
# systems
$envstr = $app1->str( qr/Site1_App1.*/ );

$output = qx{env $envstr $^X -e 'print \$ENV{Site1_App1}'};
die "error running env: $@\n" if $@;
chomp $output;
is( $output, '1', 'envstr' );


sub test_exclude {

    my $ctx = context();

    my ( $exclude, $label ) = @_;

    my $envstr = $app1->str( { Exclude => $exclude } );

    my $output;
    ok( lives{  $output = qx{env $envstr $^X -e 'print \$ENV{Site1_App1}'} },
        'grab environment' )
      or note $@;

    chomp $output;
    is( $output, '', $label );
    $ctx->release;
}

# test exclusion
test_exclude( qr/Site1_.*/, 'exclude: regexp' );
test_exclude( 'Site1_App1', 'exclude: scalar' );
test_exclude( [ 'Site1_App1' ], 'exclude: array' );

test_exclude( sub { my( $var, $val ) = @_;
                    return $var eq 'Site1_App1' ? 1 : 0 },
              'exclude: code' );


# test for TERMCAP handling
SKIP: {
    skip "no TERMCAP in environment; can't test for it", 2
      unless exists $ENV{TERMCAP};

    ok ( $app1->str( ) !~ /\bTERMCAP\b/, 'TERMCAP handling' );
    ok ( $app1->str( 'TERMCAP' ) =~ /\bTERMCAP\b/, 'TERMCAP handling' );
}

done_testing;
