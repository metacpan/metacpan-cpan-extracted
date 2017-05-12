use Test::More tests => 3;

use strict;

use Alien::Electron;

diag("Electron binary: $Alien::Electron::electron_binary");

ok(-e $Alien::Electron::electron_binary, 'binary file exists');
ok(-x $Alien::Electron::electron_binary, 'binary file is executable');

my $output = `$Alien::Electron::electron_binary t/static/`;
like($output, qr/node\.js is running/, 'saw expected output');
