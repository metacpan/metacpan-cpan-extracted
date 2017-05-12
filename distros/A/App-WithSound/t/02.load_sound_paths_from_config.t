#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec::Functions qw/catfile/;

use App::WithSound;

use Test::More tests => 6;
use Test::Warn;

my ( $app, $rc_file );

subtest 'Load configurations from the config file (simple syntax).' => sub {
    $rc_file = catfile( $FindBin::Bin, 'resource', '.with-soundrc-to-test-simple' );
    $app = App::WithSound->new( $rc_file, \%ENV );
    $app->_load_sound_paths_from_config;
    is $app->{success_sound_path}, 'foo', 'success_sound_path should be "foo"';
    is $app->{failure_sound_path}, 'bar', 'failure_sound_path should be "bar"';
    is $app->{running_sound_path}, 'baz', 'running_sound_path should be "baz"';
};

subtest 'Load configurations from the config file (ini syntax/default).' => sub {
    $rc_file = catfile( $FindBin::Bin, 'resource', '.with-soundrc-to-test' );
    $app = App::WithSound->new( $rc_file, \%ENV );
    $app->_load_sound_paths_from_config;
    is $app->{success_sound_path}, 'foo', 'success_sound_path should be "foo"';
    is $app->{failure_sound_path}, 'bar', 'failure_sound_path should be "bar"';
    is $app->{running_sound_path}, 'baz', 'running_sound_path should be "baz"';
};

subtest 'Load configurations from the config file (ini syntax/command).' => sub {
    $rc_file = catfile( $FindBin::Bin, 'resource', '.with-soundrc-to-test' );
    $app = App::WithSound->new( $rc_file, \%ENV );
    $app->_load_sound_paths_from_config('cmd1');
    is $app->{success_sound_path}, 'cmd1_foo', 'success_sound_path should be "cmd1_foo"';
    is $app->{failure_sound_path}, 'cmd1_bar', 'failure_sound_path should be "cmd1_bar"';
    is $app->{running_sound_path}, 'cmd1_baz', 'running_sound_path should be "cmd1_baz"';
};

subtest 'Load configurations from the config file (ini syntax/mix).' => sub {
    $rc_file = catfile( $FindBin::Bin, 'resource', '.with-soundrc-to-test' );
    $app = App::WithSound->new( $rc_file, \%ENV );
    $app->_load_sound_paths_from_config('cmd2');
    is $app->{success_sound_path}, 'cmd2_foo', 'success_sound_path should be "cmd2_foo"';
    is $app->{failure_sound_path}, 'bar', 'failure_sound_path should be "bar"';
    is $app->{running_sound_path}, 'baz', 'running_sound_path should be "baz"';
};

subtest 'Load configurations from the config file (ini syntax/no default).' => sub {
    $rc_file = catfile( $FindBin::Bin, 'resource', '.with-soundrc-to-test-no-default' );
    $app = App::WithSound->new( $rc_file, \%ENV );
    $app->_load_sound_paths_from_config('cmd');
    is $app->{success_sound_path}, 'cmd_foo', 'success_sound_path should be "cmd_foo"';
    is $app->{failure_sound_path}, 'cmd_bar', 'failure_sound_path should be "cmd_bar"';
    is $app->{running_sound_path}, 'cmd_baz', 'running_sound_path should be "cmd_baz"';
};

subtest 'The config file does not exist' => sub {
    $rc_file = catfile( $FindBin::Bin, 'resource', '.dummyrc' );
    $app = App::WithSound->new( $rc_file, \%ENV );
    warning_like { $app->_load_sound_paths_from_config }
    qr/\[WARNNING\] Please put config file in '$rc_file'/;
};

done_testing;
