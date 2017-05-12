#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec::Functions qw/catfile/;

use App::WithSound;

use Test::More tests => 2;

my $app;
my $rc_file = catfile( $FindBin::Bin, 'resource', '.with-soundrc-to-test' );

subtest 'Environment variables are undefined' => sub {
    $app = App::WithSound->new( $rc_file, \%ENV );
    $app->_load_sound_paths;
    is $app->{success_sound_path}, 'foo', 'success_sound_path should be "foo"';
    is $app->{failure_sound_path}, 'bar', 'failure_sound_path should be "bar"';
    is $app->{running_sound_path}, 'baz', 'running_sound_path should be "baz"';
};

subtest 'Environment variables are specified' => sub {
    $ENV{PERL_WITH_SOUND_SUCCESS} = 'bazbaz';
    $ENV{PERL_WITH_SOUND_FAILURE} = 'foobar';
    $ENV{PERL_WITH_SOUND_RUNNING} = 'foobarbaz';
    $app = App::WithSound->new( $rc_file, \%ENV );
    $app->_load_sound_paths;
    is $app->{success_sound_path}, 'bazbaz', 'success_sound_path should be "bazbaz"';
    is $app->{failure_sound_path}, 'foobar',
      'failure_sound_path should be "foobar"';
    is $app->{running_sound_path}, 'foobarbaz',
      'running_sound_path should be "foobarbaz"';
};

done_testing;
