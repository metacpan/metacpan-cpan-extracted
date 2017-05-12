#!/usr/bin/perl

use Config::Tiny;

use File::Spec;
use File::Temp;

use Test::More tests => 6;

use utf8;

# ------------------------

my($conf0) = Config::Tiny -> read('t/0');

ok($$conf0{init}{a} eq 'b', 'Hashref after read() returns correct value');

# The EXLOCK option is for BSD-based systems.

my($temp_dir)  = File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
my($temp_file) = File::Spec -> catfile($temp_dir, '0');
my($string)    =<<EOS;
[init]
a = b
EOS
my($conf1) = Config::Tiny -> read_string($string);

ok($conf1, 'read_string() returns true');

is_deeply($conf1, {init => {a => 'b'} }, 'read_string() returns expected value');

$conf1 -> write($temp_file);

my($conf2) = Config::Tiny -> read($temp_file);

is_deeply($conf1, $conf1, 'write() followed by read() works');
is_deeply($conf2, {init => {a => 'b'} }, 'write() + read() returns expected value');
is_deeply($conf0, {init => {a => 'b'} }, 'write() + read() returns expected value');
