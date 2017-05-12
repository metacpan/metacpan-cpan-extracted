#!/usr/bin/perl
# 01-live.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>
BEGIN {
    $ENV{EXISTS} = q{XXX}; 
    $ENV{PREPEND} = q{XXX}; 
    $ENV{SLASH}  = q{FAIL};
    $ENV{END}    = q{FAIL};
};

use Test::More tests => 7;
use FindBin qw($Bin);
use lib "$Bin";
use Catalyst::Test qw(TestApp);


is($ENV{FOO}, 'foo');
is($ENV{BAR}, 'bar');
is($ENV{EXISTS}, 'XXX:YYY');
is($ENV{PREPEND}, 'YYY:XXX');
is($ENV{NEW}, ':YYY');
is($ENV{SLASH}, '\:YYY');
is($ENV{END}, 'YYY\:');
