#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec::Functions qw/catfile/;

use App::WithSound;

use Test::More tests => 2;
use Test::MockObject::Extends;

my $success_sound_path =
  catfile( $FindBin::Bin, 'resource', 'dummy_success.mp3' );
my $failure_sound_path =
  catfile( $FindBin::Bin, 'resource', 'dummy_failure.mp3' );

$ENV{PERL_WITH_SOUND_SUCCESS} = $success_sound_path;
$ENV{PERL_WITH_SOUND_FAILURE} = $failure_sound_path;

my $rc_file = catfile( $FindBin::Bin, 'resource', '.with-soundrc-to-test' );

my $app = App::WithSound->new( $rc_file, \%ENV );
$app->_init;

my $mock = Test::MockObject::Extends->new($app);

subtest 'Playback sound rightly in status:success' => sub {
    $mock->mock(
        "_play_mp3",
        sub {
            my ( $self, $mp3_file_path, $status ) = @_;
            is $mp3_file_path, $success_sound_path,
              "Sound file path in status:success";
            is $status, "success", "Status";
        }
    );
    $app->_play_sound(0);
};

subtest 'Playback sound rightly in status:failure' => sub {
    $mock->mock(
        "_play_mp3",
        sub {
            my ( $self, $mp3_file_path, $status ) = @_;
            is $mp3_file_path, $failure_sound_path,
              "Sound file path in status:failuer";
            is $status, "failure", "Status";
        }
    );
    $app->_play_sound(1);
};
done_testing;
