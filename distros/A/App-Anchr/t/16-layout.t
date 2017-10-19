#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use App::Cmd::Tester::CaptureExternal;

use App::Anchr;

my $result = test_app( 'App::Anchr' => [qw(help layout)] );
like( $result->stdout, qr{layout}, 'descriptions' );

$result = test_app( 'App::Anchr' => [qw(layout)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Anchr' => [qw(layout t/not_exists)] );
like( $result->error, qr{need .+input file}, 'need 3 infiles' );

$result = test_app( 'App::Anchr' => [qw(layout t/not_exists t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

{
    my $tempdir = Path::Tiny->tempdir;
    $result = test_app(
        'App::Anchr' => [
            qw(layout t/24_4.ovlp.tsv t/24_4.relation.tsv t/24_4.strand.fasta),
            qw(--oa t/24_4.anchor.ovlp.tsv -o),
            $tempdir->child('conTig.fasta'),
        ]
    );
    is( $result->error, undef, 'no exceptions' );
    is( ( scalar grep {/\S/} split( /\n/, $result->stderr ) ), 1, 'stderr line count' );
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 0, 'line count' );

    ok( $tempdir->child("conTig.fasta")->is_file, 'outfile exists' );

    is( scalar $tempdir->child("conTig.fasta")->lines, 2, 'line count' );
}

done_testing();
