#!perl

use strict;
use warnings;

use Test::More;
use App::Cmd::Tester;

use App::Report::Generator;
use Data::Dumper;

use Cwd;
use File::Basename ();
use File::Path;
use File::Spec ();
use JSON::Any;
use File::Slurp;

my $dir = File::Spec->catdir( getcwd(), 'test_output' );

rmtree $dir;
END { rmtree $dir }
mkpath $dir;
mkpath( File::Spec->catdir( $dir, 'etc' ) );

my $examples = File::Spec->catdir( getcwd(), 'examples' );
my $coder = JSON::Any->new();
my $example_cfgs = File::Spec->catfile( $examples, 'etc', '*.jsn' );
foreach my $cfg ( glob($example_cfgs) )
{
    my $tgtfn = File::Spec->catfile( $dir, 'etc', File::Basename::basename($cfg) );
    my $testfcnt = read_file($cfg);
    my $testcfg = $coder->decode($testfcnt);
    my $test_renderer = $testcfg->{"Report::Generator::Render::TT2"};
    $test_renderer->{output} = File::Spec->catfile( $dir, $test_renderer->{output} );
    $test_renderer->{template} = File::Spec->catfile( $examples, $test_renderer->{template} );
    write_file( $tgtfn, $coder->encode($testcfg) );
}

$ENV{APP_GENREPORT_CONFIGBASE} = 'test_output';
my $result = test_app( 'App::Report::Generator' => ['demo-report'] );

is( $result->stderr, '',    'nothing sent to sderr' );
is( $result->error,  undef, 'threw no exceptions' );

ok( -f File::Spec->catfile( $dir, "demo.sql" ), "generated file exists" );

done_testing();
