use strict;
use warnings;
our $VERSION = 0.001_000;

use Test::More tests => 12;
use File::Spec;
use Env qw( @PATH );
use IPC::Cmd qw(can_run);
use English qw(-no_match_vars);  # for $OSNAME

use_ok('Alien::Pluto');
unshift @PATH, Alien::Pluto->bin_dir;

# check if `pluto` can be run, if so get path to binary executable
my $pluto_path = undef;
#if ($OSNAME eq 'MSWin32') {
#    $pluto_path = can_run('pluto.exe');
#}
#else {
    $pluto_path = can_run('pluto');
#}
ok(defined $pluto_path, '`pluto` binary path is defined');
isnt($pluto_path, q{}, '`pluto` binary path is not empty');

# split pluto executable file from directory containing it
(my $pluto_volume, my $pluto_directories, my $pluto_file) = File::Spec->splitpath($pluto_path);
my $pluto_directory = File::Spec->catpath($pluto_volume, $pluto_directories, q{});

# test pluto directory permissions
ok(defined $pluto_directory, 'Alien::Pluto->bin_dir() is defined');
isnt($pluto_directory, q{}, 'Alien::Pluto->bin_dir() is not empty');
ok(-e $pluto_directory, 'Alien::Pluto->bin_dir() exists');
ok(-r $pluto_directory, 'Alien::Pluto->bin_dir() is readable');
ok(-d $pluto_directory, 'Alien::Pluto->bin_dir() is a directory');

# test pluto executable permissions
ok(-e $pluto_path, 'pluto exists');
ok(-r $pluto_path, 'pluto is readable');
ok(-f $pluto_path, 'pluto is a file');
ok(-x $pluto_path, 'pluto is executable');
