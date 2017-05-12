#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec::Functions qw/catfile/;

use App::WithSound;

use Test::More tests => 1;
use Test::MockObject::Extends;

subtest 'Playback mp3 rightly' => sub {

    my $rc_file = catfile( $FindBin::Bin, 'resource', '.with-soundrc-to-test' );
    my $expected_success_mp3 = catfile( $FindBin::Bin, 'resource', 'dummy_success.mp3' );
    my $expected_failure_mp3 = catfile( $FindBin::Bin, 'resource', 'dummy_failure.mp3' );
    my $env = +{
        PERL_WITH_SOUND_SUCCESS => $expected_success_mp3,
        PERL_WITH_SOUND_FAILURE => $expected_failure_mp3,
    };
    my $app = App::WithSound->new($rc_file, $env);

    my $app_mock = Test::MockObject::Extends->new($app);
    $app_mock->mock(
        '_detect_sound_play_command',
        sub {
            my ($self) = @_;
            $self->{sound_player} = '/path/to/mpg123';
            return $self;
        }
    );
    $app_mock->_init;
    $app_mock->mock(
        '_play_mp3_in_child',
        sub {
            my ($self, $sound_play_command, $mp3_file_path) = @_;
            is $sound_play_command, '/path/to/mpg123', 'the sound play command is eq to given';
            is $mp3_file_path, $expected_success_mp3, 'the mp3 file path is given';
        }
    );
    $app_mock->_play_sound(0);

    $app_mock->mock(
        '_play_mp3_in_child',
        sub {
            my ($self, $sound_play_command, $mp3_file_path) = @_;
            is $sound_play_command, '/path/to/mpg123', 'the sound play command is eq to given';
            is $mp3_file_path, $expected_failure_mp3, 'the mp3 file path is given';
        }
    );
    $app_mock->_play_sound(1);
};

done_testing;
