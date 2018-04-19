#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

#use App::Cmd::Tester;
use App::Cmd::Tester::CaptureExternal;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help template)] );
like( $result->stdout, qr{template}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(template)] );
like( $result->error, qr{need .+ dir}, 'need directory' );

$result = test_app( 'App::Egaz' => [qw(template t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'not exists' );

{
    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    $result = test_app(
        'App::Egaz' => [
            "template", "$t_path/pseudocat", "$t_path/pseudopig", "--rawphylo",
            "--vcf",    "--aligndb",         "--verbose",
        ]
    );

    is( $result->error, undef, 'threw no exceptions' );
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 0, 'no stdout' );
    ok( $tempdir->child("1_pair.sh")->is_file,       '1_pair.sh exists' );
    ok( $tempdir->child("2_rawphylo.sh")->is_file,   '2_rawphylo.sh exists' );
    ok( $tempdir->child("4_vcf.sh")->is_file,        '4_vcf.sh exists' );
    ok( $tempdir->child("7_chr_length.sh")->is_file, '7_chr_length.sh exists' );
    like( $result->stderr, qr{name: pseudocat.+name: pseudopig}s, 'names and directories' );

    chdir $cwd;    # Won't keep tempdir
}

{
    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    $result = test_app(
        'App::Egaz' => [
            "template", "$t_path/pseudocat", "$t_path/pseudopig", "--self",
            "--circos", "--verbose",
        ]
    );

    is( $result->error, undef, 'threw no exceptions' );
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 0, 'no stdout' );
    ok( $tempdir->child("1_self.sh")->is_file,   '1_self.sh exists' );
    ok( $tempdir->child("4_circos.sh")->is_file, '4_circos.sh exists' );
    like( $result->stderr, qr{name: pseudocat.+name: pseudopig}s, 'names and directories' );

    chdir $cwd;    # Won't keep tempdir
}

done_testing();
