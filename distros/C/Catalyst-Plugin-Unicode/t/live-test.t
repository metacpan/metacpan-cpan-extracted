#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 12;
use utf8;
use IO::Scalar;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use ok 'TestApp';

our $TEST_FILE = IO::Scalar->new(\"this is a test");
sub IO::Scalar::FILENO { -1 }; # needed?

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');

{
    $mech->get_ok('http://localhost/unicode', 'get unicode');
    my $content = $mech->content;
    ok(!utf8::is_utf8($content), 'not utf8');
    utf8::decode($content);
    ok(utf8::is_utf8($content), 'now its utf8');
    like $content, qr/ほげ/, 'content contains hoge';
}

{
    $mech->get_ok('http://localhost/not_unicode', 'get bytes');
    my $content = $mech->content; 
    ok(!utf8::is_utf8($content), 'not utf8');
    my $regex = "\x{1234}\x{5678}";
    utf8::encode($regex);
    like $content, qr/$regex/, 'got 1234 5678';
}

{
    $mech->get_ok('http://localhost/file', 'get file');
    $mech->content_like(qr/this is a test/, 'got filehandle contents');
}
