use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help maskfasta)] );
like( $result->stdout, qr{maskfasta}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(maskfasta)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(maskfasta t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Egaz' => [qw(maskfasta t/pseudocat.fa t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

{    # real run
    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    my $yaml = <<YAML;
---
cat: 1-20

YAML

    Path::Tiny::path("runlist.yml")->spew($yaml);
    my $fasta = Path::Tiny::path("$t_path/pseudocat.fa")->slurp;

    $result = test_app( 'App::Egaz' => [ "maskfasta", "$t_path/pseudocat.fa", "runlist.yml" ] );
    like( $result->stdout, qr{ttggcatctatcctatcaca}s, 'soft masked' );
    ok(uc $result->stdout eq uc $fasta, 'sequence not changed');

    $result = test_app( 'App::Egaz' => [ "maskfasta", "$t_path/pseudocat.fa", "runlist.yml", "--hard" ] );
    like( $result->stdout, qr{N{20}}s, 'hard masked' );
    ok(uc $result->stdout ne uc $fasta, 'sequence changed');

    chdir $cwd;    # Won't keep tempdir
}

done_testing();
