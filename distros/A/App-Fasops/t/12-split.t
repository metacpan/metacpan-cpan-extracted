use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;
use App::Fasops::Common;

my $result = test_app( 'App::Fasops' => [qw(help split)] );
like( $result->stdout, qr{split}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(split)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(split t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Fasops' => [qw(split t/example.fas -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 24, 'line count' );

$result = test_app( 'App::Fasops' => [qw(split t/example.fas -o stdout --simple)] );
like( $result->stdout, qr{^>S288c$}m, 'simple headers' );
unlike( $result->stdout, qr{I\(\+\)}, 'no positions' );

my Path::Tiny $tempdir = Path::Tiny::tempdir();
$result = test_app( 'App::Fasops' => [ qw(split t/example.fas --chr -o ), $tempdir->stringify ] );
is($result->stdout, "" );
is($result->stderr, "" );
ok( Path::Tiny::path( $tempdir, "I.fas" )->is_file, "file exists" );
undef $tempdir;

done_testing();
