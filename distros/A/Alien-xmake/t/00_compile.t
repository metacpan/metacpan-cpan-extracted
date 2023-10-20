use strict;
use warnings;
use lib 'lib', '../blib/lib', '../lib';
use Test::More 0.98;
use Env qw[@PATH];
#
use Alien::xmake;
#
diag 'Alien::xmake is a ' . Alien::xmake->install_type . ' install';
unshift @PATH, Alien::xmake->bin_dir;
my $exe = Alien::xmake->exe;
ok $exe, 'xmake is installed as ' . $exe;
diag 'Running `xmake --version`';
my $run = `$exe --version`;
ok $run, $run;
ok( Alien::xmake->version, Alien::xmake->version );
#
done_testing;
