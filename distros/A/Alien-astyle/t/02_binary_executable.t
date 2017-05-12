use strict;
use warnings;
our $VERSION = 0.003_000;

use Test::More tests => 12;
use File::Spec;
use Env qw( @PATH );
use IPC::Cmd qw(can_run);
use English qw(-no_match_vars);  # for $OSNAME

use_ok('Alien::astyle');
unshift @PATH, Alien::astyle->bin_dir;

# check if `astyle` can be run, if so get path to binary executable
my $astyle_path = undef;
if ($OSNAME eq 'MSWin32') {
    $astyle_path = can_run('AStyle.exe');
}
else {
    $astyle_path = can_run('astyle');
}
ok(defined $astyle_path, '`astyle` binary path is defined');
isnt($astyle_path, q{}, '`astyle` binary path is not empty');

# split astyle executable file from directory containing it
(my $astyle_volume, my $astyle_directories, my $astyle_file) = File::Spec->splitpath($astyle_path);
my $astyle_directory = File::Spec->catpath($astyle_volume, $astyle_directories, q{});

# test astyle directory permissions
ok(defined $astyle_directory, 'Alien::astyle->bin_dir() is defined');
isnt($astyle_directory, q{}, 'Alien::astyle->bin_dir() is not empty');
ok(-e $astyle_directory, 'Alien::astyle->bin_dir() exists');
ok(-r $astyle_directory, 'Alien::astyle->bin_dir() is readable');
ok(-d $astyle_directory, 'Alien::astyle->bin_dir() is a directory');

# test astyle executable permissions
ok(-e $astyle_path, 'astyle exists');
ok(-r $astyle_path, 'astyle is readable');
ok(-f $astyle_path, 'astyle is a file');
ok(-x $astyle_path, 'astyle is executable');
