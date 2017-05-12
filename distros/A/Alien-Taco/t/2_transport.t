# Test transport module.

use strict;

use IO::String;

use Test::More tests => 3;

BEGIN {use_ok('Alien::Taco::Transport');}

my $in = '';
my $out = '';

my $in_io = new IO::String($in);
my $out_io = new IO::String($out);

my $xp = new Alien::Taco::Transport(in => $in_io, out => $out_io);

$xp->write({test_hash => 1});

is($out, "{\"test_hash\":1}\n// END\n", 'write test hash');

$in = "{\"test_input\":2}\n// END\n";

is_deeply($xp->read(), {test_input => 2}, 'read test hash');
