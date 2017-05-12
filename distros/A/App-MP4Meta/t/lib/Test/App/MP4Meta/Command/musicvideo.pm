use 5.010;
use strict;
use warnings;

package Test::App::MP4Meta::Command::musicvideo;
use base qw(TestBase);

use Test::More;
use App::Cmd::Tester;

use App::MP4Meta;

sub test_command : Test(6) {
    my $result;

    # test no arguments
    $result = test_app( 'App::MP4Meta' => [qw(musicvideo)] );
    is( $result->stdout, '' );
    is( $result->stderr, '', 'nothing sent to sderr' );
    like( $result->error, qr/Error: too few arguments/ );

    # test file does not exist
    $result =
      test_app( 'App::MP4Meta' => [qw(musicvideo /does/not/exist.mp4)] );
    is( $result->stdout, '' );
    is( $result->stderr, '', 'nothing sent to sderr' );
    like( $result->error, qr!Error: /does/not/exist.mp4 does not exist! );
}

1;
