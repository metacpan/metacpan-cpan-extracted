use strict;
use warnings;
our $VERSION = 0.001_000;

use Test::More tests => 12;
use File::Spec;
use Env qw( @PATH );
use IPC::Cmd qw(can_run);
use English qw(-no_match_vars);  # for $OSNAME

use_ok('Alien::Texinfo');
unshift @PATH, Alien::Texinfo->bin_dir;

# check if `makeinfo` can be run, if so get path to binary executable
my $makeinfo_path = undef;
#if ($OSNAME eq 'MSWin32') {
#    $makeinfo_path = can_run('makeinfo.exe');
#}
#else {
    $makeinfo_path = can_run('makeinfo');
#}
ok(defined $makeinfo_path, '`makeinfo` binary path is defined');
isnt($makeinfo_path, q{}, '`makeinfo` binary path is not empty');

# split makeinfo executable file from directory containing it
(my $makeinfo_volume, my $makeinfo_directories, my $makeinfo_file) = File::Spec->splitpath($makeinfo_path);
my $makeinfo_directory = File::Spec->catpath($makeinfo_volume, $makeinfo_directories, q{});

# test makeinfo directory permissions
ok(defined $makeinfo_directory, 'Alien::Texinfo->bin_dir() is defined');
isnt($makeinfo_directory, q{}, 'Alien::Texinfo->bin_dir() is not empty');
ok(-e $makeinfo_directory, 'Alien::Texinfo->bin_dir() exists');
ok(-r $makeinfo_directory, 'Alien::Texinfo->bin_dir() is readable');
ok(-d $makeinfo_directory, 'Alien::Texinfo->bin_dir() is a directory');

# test makeinfo executable permissions
ok(-e $makeinfo_path, 'makeinfo exists');
ok(-r $makeinfo_path, 'makeinfo is readable');
ok(-f $makeinfo_path, 'makeinfo is a file');
ok(-x $makeinfo_path, 'makeinfo is executable');
