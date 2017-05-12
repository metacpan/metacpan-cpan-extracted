#!/usr/bin/perl

use Config::Tiny;

use File::Spec;
use File::Temp;

use Test::More tests => 7;

use utf8;

# ------------------------

my($config) = Config::Tiny -> read('t/04.utf8.txt', 'utf8');

ok($$config{utf8_data}{Name}  eq 'Δ Lady',            'Hashref after read() returns correct value');
ok($$config{utf8_data}{Class} eq 'Reichwaldstraße',   'Hashref after read() returns correct value');
ok($$config{utf8_data}{Type}  eq 'Πηληϊάδεω Ἀχιλῆος', 'Hashref after read() returns correct value');

# The EXLOCK option is for BSD-based systems.

my($temp_dir)  = File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
my($temp_file) = File::Spec -> catfile($temp_dir, 'write.utf8.conf');
my($string)    =<<EOS;
[init]
weird_text     = Reichwaldstraße
EOS
my($conf1) = Config::Tiny -> read_string($string);

ok($conf1, 'read_string() returns true');

is_deeply($conf1, {init => {weird_text => 'Reichwaldstraße'} }, 'read_string() returns expected value');

$conf1 -> write($temp_file, 'utf8');

my($conf2) = Config::Tiny -> read($temp_file, 'encoding(utf8)');

is_deeply($conf1, $conf1, 'write() followed by read() works');
is_deeply($conf2, {init => {weird_text => 'Reichwaldstraße'} }, 'write() + read() returns expected value');
