use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::RL;

my $result = test_app( 'App::RL' => [qw(help gff)] );
like( $result->stdout, qr{gff}, 'descriptions' );

$result = test_app( 'App::RL' => [qw(gff)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::RL' => [qw(gff t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::RL' => [qw(gff t/NC_007942.gff -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 2, 'line count' );
like( $result->stdout, qr{1\-152218},  'runlist exists' );
like( $result->stdout, qr{NC_007942:}, 'chromosomes exist' );

{
    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    test_app( 'App::RL' => [ "gff", "$t_path/NC_007942.gff", "-t", "CDS", "-o", "cds.yml", ] );

    test_app( 'App::RL' => [ "gff", "$t_path/NC_007942.rm.gff", "-o", "repeat.yml", ] );

    $result = test_app( 'App::RL' => [ "merge", "cds.yml", "repeat.yml", "-o", "stdout", ] );

    my $expect = join "", Path::Tiny::path("$t_path/anno.yml")->lines;
    is( $result->stdout, $expect, 'matched with expect' );

    chdir $cwd;    # Won't keep tempdir
}

done_testing();
