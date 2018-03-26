use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help masked)] );
like( $result->stdout, qr{masked}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(masked)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(masked t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Egaz' => [qw(masked t/pseudocat.fa t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Egaz' => [qw(masked t/pseudocat.fa)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 2, 'line count' );
like( $result->stdout, qr{cat: 315-352}, 'first part of cat' );

$result = test_app( 'App::Egaz' => [qw(masked t/pseudopig.fa)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 3, 'line count' );
like( $result->stdout, qr{pig2: 548-582}, 'first part of pig2' );

{    # real run
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    my $fasta = <<FASTA;
>cat
TTGGCATCTAtcctaTCACAAATTGAATGCNNNGAAGACAAAATTTGGTC
>cat
TTGGCATCTAtcctaTCACAAATTGAATGCNNNGAAGACAAAATTTGGTC
FASTA

    Path::Tiny::path("cat.fasta")->spew($fasta);

    $result = test_app( 'App::Egaz' => [qw(masked cat.fasta) ] );
    like( $result->stdout, qr{cat: 11-15,31-33}, 'soft masked' );

    $result = test_app( 'App::Egaz' => [qw(masked cat.fasta --gaps) ] );
    like( $result->stdout, qr{cat: 31-33}, 'gaps' );

    chdir $cwd;    # Won't keep tempdir
}

done_testing();
