use 5.010;
use strict;
use warnings;

package Test::App::MP4Meta::Command::tv;
use base qw(TestBase);

use Test::More;
use App::Cmd::Tester;

use App::MP4Meta;

#use AtomicParsley::Command;

sub test_arguments : Test(6) {
    my $result;

    # test no arguments
    $result = test_app( 'App::MP4Meta' => [qw(tv)] );
    is( $result->stdout, '' );
    is( $result->stderr, '', 'nothing sent to sderr' );
    like( $result->error, qr/Error: too few arguments/ );

    # test file does not exist
    $result = test_app( 'App::MP4Meta' => [qw(tv /does/not/exist.mp4)] );
    is( $result->stdout, '' );
    is( $result->stderr, '', 'nothing sent to sderr' );
    like( $result->error, qr!Error: /does/not/exist.mp4 does not exist! );
}

# for some reason, using test_app causes the program to hang indefinitely
# no idea why...
# sub test_tvdb_default : Test(3) {
#     my $self = shift;
#
#     #return 'no live testing' unless $self->can_live_test();
#
#     my $ap = AtomicParsley::Command->new();
#
#     my $tempfile = $self->get_temporary_m4v('Heroes.S03E01');
#     diag($tempfile);
#
#     # call tv with right arguments
#     my $result = test_app( 'App::MP4Meta' => [qw(tv --verbose Heroes.S03E01.m4v)] );
#     is( $result->stdout, '' );
#     is( $result->error, '' );
#     is( $result->stderr, '', 'nothing sent to sderr' );
# }

1;
