use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;
use Path::Tiny;
use IPC::Cmd;

SKIP: {
    skip "mafft not installed", 5 unless IPC::Cmd::can_run('mafft');

    my $result;

    $result = test_app( 'App::Fasops' => [qw(refine t/refine.fas -o stdout)] );
    is( scalar( grep {/\S/} split( /\n/, $result->stdout ) ), 16, 'line count' );
    like( ( split /\n\n/, $result->stdout )[0], qr{\-\-\-}s, 'dash added' );

    my $section = ( split /\n\n/, $result->stdout )[1];
    $section = join "", grep { !/^>/ } split( /\n/, $section );
    my $count = $section =~ tr/-/-/;
    is( $count, 11, 'count of dashes' );

    $result = test_app( 'App::Fasops' => [qw(refine t/refine.fas -p 2 -o stdout)] );
    is( scalar( grep {/\S/} split( /\n/, $result->stdout ) ), 16, 'line count' );
    like( ( grep {/\S/} split /\n\n/, $result->stdout )[0], qr{\-\-\-}s, 'dash added' );
}

SKIP: {
    skip "muscle not installed", 1 unless IPC::Cmd::can_run('muscle');

    my $result = test_app( 'App::Fasops' => [qw(refine t/refine.fas --msa muscle --quick -o stdout)] );
    my $output = $result->stdout;
    $output =~ s/\-//g;
    $output =~ s/\s+//g;
    my $original = path("t/refine.fas")->slurp;
    $original =~ s/\-//g;
    $original =~ s/\s+//g;
    is( $output, $original, 'same without dashes' );

    $result = test_app( 'App::Fasops' => [qw(refine t/refine2.fas --msa muscle --outgroup -o stdout)] );
    like($result->stdout, qr{CA-GT}, 'outgroup trimmed' );

    $result = test_app( 'App::Fasops' => [qw(refine t/refine2.fas --msa muscle -o stdout)] );
    like($result->stdout, qr{CA--GT}, 'outgroup not trimmed' );

}

done_testing();
