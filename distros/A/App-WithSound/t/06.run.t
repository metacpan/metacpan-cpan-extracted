#!perl

use strict;
use warnings;
use utf8;
use FindBin;
use File::Spec::Functions qw/catfile/;

use App::WithSound;

use Test::More;
use Test::MockObject::Extends;

$ENV{PERL_WITH_SOUND_SUCCESS} =
  catfile( $FindBin::Bin, 'resource', 'dummy_success.mp3' );
$ENV{PERL_WITH_SOUND_FAILURE} =
  catfile( $FindBin::Bin, 'resource', 'dummy_failure.mp3' );
$ENV{PERL_WITH_SOUND_RUNNING} =
  catfile( $FindBin::Bin, 'resource', 'dummy_running.mp3' );
my $rc_file = catfile( $FindBin::Bin, 'resource', '.with-soundrc-to-test' );

# mock _play_mp3_in_child so this test script doesn't play sound really.
my $app = App::WithSound->new( $rc_file, \%ENV );
my $mock = Test::MockObject::Extends->new( $app );
$mock->mock( '_play_mp3_in_child', sub{ 0 } );

subtest 'Run success' => sub {
    my @args = ( 'perl', '-e', 'exit(0);' );
    is $app->run(@args), 0;
};

subtest 'Run failure' => sub {
    my @args = ( 'perl', '-e', 'exit(1);' );
    is $app->run(@args), 1;
};

done_testing;
