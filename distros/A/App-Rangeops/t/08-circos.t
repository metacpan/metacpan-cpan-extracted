use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Rangeops;

my $result = test_app( 'App::Rangeops' => [qw(help circos)] );
like( $result->stdout, qr{circos}, 'descriptions' );

$result
    = test_app( 'App::Rangeops' => [qw(circos t/II.connect.tsv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 10, 'line count' );
unlike( $result->stdout, qr{fill_color}, 'links' );

$result
= test_app( 'App::Rangeops' => [qw(circos t/II.connect.tsv --highlight -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 14, 'line count' );
like( $result->stdout, qr{fill_color}, 'highlights' );

done_testing();
