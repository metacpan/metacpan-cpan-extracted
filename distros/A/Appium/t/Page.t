#! /usr/bin/perl

use strict;
use warnings;
use Appium;
use Cwd qw/abs_path/;
use Capture::Tiny qw/capture_stdout/;
use File::Basename qw/dirname/;
use FileHandle;
use IO::Socket::INET;
use IPC::Cmd qw/can_run/;
use Test::More;

plan skip_all => "Release tests not required for installation."
  unless $ENV{RELEASE_TESTING};

my $sock = IO::Socket::INET->new(
    PeerAddr => 'localhost',
    PeerPort => 4723,
    Timeout => 4
);
plan skip_all => "No Appium server found" unless $sock;

my $xcrun = can_run('xcrun');
plan skip_all => "No xcrun binary found" unless $xcrun;

my $sdk = `$xcrun --sdk iphonesimulator -show-sdk-version` + 0;

my $test_app = dirname(abs_path(__FILE__)) . '/fixture/TestApp.zip';

my $appium = Appium->new(
    caps => {
        app => $test_app,
        deviceName => 'iPhone 6',
        platformName => 'iOS',
        platformVersion => $sdk,
    }
);

$appium->find_element('TextField1', 'name')->send_keys('5');
my $page = capture_stdout { $appium->page };
ok($page =~ /UIAWindow/, 'page finds a source window to print out');
ok($page =~ /TextField1/, 'and it has the expected children elements of its own');
ok($page =~ /value\s+:\s+5/, 'and it has text that we input manually');

done_testing;
