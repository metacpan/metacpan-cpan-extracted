use strict;
use warnings;

use Appium;
use Cwd qw/abs_path/;
use Capture::Tiny qw/capture_stdout/;
use File::Basename qw/dirname/;
use IO::Socket::INET;
use IPC::Cmd qw/can_run/;
use Test::Spec;

plan skip_all => "Release tests not required for installation."
  unless $ENV{RELEASE_TESTING};

my $has_appium_server = IO::Socket::INET->new(
    PeerAddr => 'localhost',
    PeerPort => 4723,
    Timeout => 2
);
plan skip_all => "No Appium server found" unless $has_appium_server;
plan skip_all => 'No adb found' unless can_run('adb');

my $devices = `adb devices`;
my $is_device_available = $devices =~ /device$|emulator/m;
plan skip_all => 'No running android devices found: ' . $devices
  unless $is_device_available;

describe 'Android Page command' => sub {
    my $appium = Appium->new( caps => {
        app => dirname(abs_path(__FILE__)) . '/fixture/ApiDemos-debug.apk',
        deviceName => 'Android Emulator',
        platformName => 'Android',
        platformVersion => '4.4.4'
    });

    my $page;
    before each => sub {
        $page = capture_stdout { $appium->page };
    };

    it 'should print out the elements' => sub {
        ok( $page );
    };

    it 'should print out all three attributes when appropriate' => sub {
        my $node_output = q(android.widget.TextView
  text: NFC
  resource-id: android:id/text1
  content-desc: NFC);

        ok( index( $page, $node_output ) != -1 );
    };

    it 'should skip attributes when they are empty' => sub {
        my $node_output = q(android.widget.FrameLayout
  resource-id: android:id/action_bar_containe);

        ok( index( $page, $node_output ) != -1 );
    };

    it 'should always have at least one attribute' => sub {
        unlike( $page, qr/^android\.*\n\n/ );
    };

    it 'should quit Appium explicitly to avoid race conditions' => sub {
        # This actually belongs in an `after all => sub { };` block,
        # but there's an odd race condition with `prove` where this
        # test's `after all` block doesn't get called in time. The
        # next e2e test starts up, and then Appium is sad that there's
        # already an existing session.
        $appium->quit;
        undef $appium;
    };

};


runtests;
