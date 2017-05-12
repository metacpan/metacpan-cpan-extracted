#!perl

use strict;
use warnings;
use utf8;

use App::WithSound;

use Test::More tests => 3;
use Test::Warn;

my $app;

subtest 'Environment variables are undefined' => sub {
    $app = App::WithSound->new( undef, \%ENV );
    $app->_load_sound_paths_from_env;
    is $app->{success_sound_path}, undef,
      'success_sound_path should be undefined';
    is $app->{failure_sound_path}, undef,
      'failure_sound_path should be undefined';
    is $app->{running_sound_path}, undef,
      'running_sound_path should be undefined';
};

subtest 'Deprecated environment variables are specified' => sub {
    my %env;
    $env{WITH_SOUND_SUCCESS} = 'foo';
    $env{WITH_SOUND_FAILURE} = 'bar';
    $env{WITH_SOUND_RUNNING} = 'baz';
    $app = App::WithSound->new( undef, \%env );

    warnings_like { $app->_load_sound_paths_from_env }
        [
            qr{\[WARNING\] "WITH_SOUND_FAILURE" is deprecated. Please use "PERL_WITH_SOUND_FAILURE"},
            qr{\[WARNING\] "WITH_SOUND_RUNNING" is deprecated. Please use "PERL_WITH_SOUND_RUNNING"},
            qr{\[WARNING\] "WITH_SOUND_SUCCESS" is deprecated. Please use "PERL_WITH_SOUND_SUCCESS"},
        ];

    is $app->{success_sound_path}, 'foo', 'success_sound_path should be "foo"';
    is $app->{failure_sound_path}, 'bar', 'failure_sound_path should be "bar"';
    is $app->{running_sound_path}, 'baz', 'running_sound_path should be "baz"';
};

subtest 'Environment variables are specified' => sub {
    my %env;
    $env{PERL_WITH_SOUND_SUCCESS} = 'foo';
    $env{PERL_WITH_SOUND_FAILURE} = 'bar';
    $env{PERL_WITH_SOUND_RUNNING} = 'baz';

    $app = App::WithSound->new( undef, \%env );

    $app->_load_sound_paths_from_env;
    is $app->{success_sound_path}, 'foo', 'success_sound_path should be "foo"';
    is $app->{failure_sound_path}, 'bar', 'failure_sound_path should be "bar"';
    is $app->{running_sound_path}, 'baz', 'running_sound_path should be "baz"';
};

done_testing;
