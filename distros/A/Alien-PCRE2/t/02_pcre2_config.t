use strict;
use warnings;
our $VERSION = 0.027_000;

use Test2::V0;
use Test::Alien;
use Alien::PCRE2;
use File::Spec;  # for splitpath() and catpath()
use Env qw( @PATH );
use IPC::Cmd qw(can_run);
use English qw(-no_match_vars);  # for $OSNAME
use Capture::Tiny qw( capture_merged );
use Data::Dumper;  # DEBUG

plan(28);

# load alien
alien_ok('Alien::PCRE2', 'Alien::PCRE2 loads successfully and conforms to Alien::Base specifications');

my $pcre2_bin_dirs = [ Alien::PCRE2->bin_dir() ];
print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_pcre2_config.t, have $pcre2_bin_dirs = '}, Dumper($pcre2_bin_dirs), q{'}, "\n\n";
unshift @PATH, @{ $pcre2_bin_dirs };

# test pcre2 directory permissions
foreach my $pcre2_bin_dir (@{$pcre2_bin_dirs}) {
    ok(defined $pcre2_bin_dir, 'Alien::PCRE2->bin_dir() element is defined');
    isnt($pcre2_bin_dir, q{}, 'Alien::PCRE2->bin_dir() element is not empty');
    ok(-e $pcre2_bin_dir, 'Alien::PCRE2->bin_dir() element exists');
    ok(-r $pcre2_bin_dir, 'Alien::PCRE2->bin_dir() element is readable');
    ok(-d $pcre2_bin_dir, 'Alien::PCRE2->bin_dir() element is a directory');
}

# check if `pcre2-config` can be run, if so get path to binary executable
my $pcre2_path = undef;
# DEV NOTE, CORRELATION #ap002: Windows hack, shell script `pcre2-config` not found as executable
if ($OSNAME eq 'MSWin32') {
#    $pcre2_path = can_run('pcre2-config');
    $pcre2_path = can_run('pcre2grep');
}
else {
    $pcre2_path = can_run('pcre2-config');
}
print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_pcre2_config.t, have $pcre2_path = '}, $pcre2_path, q{'}, "\n\n";
ok(defined $pcre2_path, 'pcre2-config binary path is defined');
isnt($pcre2_path, q{}, 'pcre2-config binary path is not empty');

# split pcre2-config executable file from directory containing it
(my $pcre2_volume, my $pcre2_directories, my $pcre2_file) = File::Spec->splitpath($pcre2_path);
my $pcre2_directory = File::Spec->catpath($pcre2_volume, $pcre2_directories, q{});
print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_pcre2_config.t, have $pcre2_directory = '}, $pcre2_directory, q{'}, "\n\n";

# DEV NOTE, CORRELATION #ap002: Windows hack, shell script `pcre2-config` not found as executable
if ($OSNAME eq 'MSWin32') {
    $pcre2_path = File::Spec->catpath($pcre2_volume, $pcre2_directories, q{pcre2-config});
print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_pcre2_config.t, have WINDOWS HACK $pcre2_path = '}, $pcre2_path, q{'}, "\n\n";
}

# test pcre2 directory permissions
ok(defined $pcre2_directory, 'can_run() binary directory is defined');
isnt($pcre2_directory, q{}, 'can_run() binary directory is not empty');
ok(-e $pcre2_directory, 'can_run() binary directory exists');
ok(-r $pcre2_directory, 'can_run() binary directory is readable');
ok(-d $pcre2_directory, 'can_run() binary directory is a directory');

# test pcre2 executable permissions
ok(-e $pcre2_path, 'pcre2-config binary path exists');
ok(-r $pcre2_path, 'pcre2-config binary path is readable');
ok(-f $pcre2_path, 'pcre2-config binary path is a file');

# DEV NOTE, CORRELATION #ap002: Windows hack, shell script `pcre2-config` not found as executable
SKIP: {
    skip 'MS Windows OS does not recognize shell script files as executable', 1 if ($OSNAME eq 'MSWin32');
    ok(-x $pcre2_path, 'pcre2-config binary path is executable');
}

# DEV NOTE, CORRELATION #ap002: Windows hack, shell script `pcre2-config` not found as executable
# check if `sh` can be run, if so get path to binary executable
my $sh_path = undef;
$sh_path = can_run('sh');
print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_pcre2_config.t, have $sh_path = '}, $sh_path, q{'}, "\n\n";


SKIP: {
    skip 'sh Bourne shell not found, can not run pcre2-config shell script', 11 if ((not defined $sh_path) or ($sh_path eq q{}));

    ok(defined $sh_path, 'sh Bourne shell binary path is defined');
    isnt($sh_path, q{}, 'sh Bourne shell binary path is not empty');

    # run `pcre2-config --version`, check for valid output
    my $version = [ split /\r?\n/, capture_merged { system $sh_path . q{ } . $pcre2_path . ' --version'; }];  # WINDOWS HACK: must explicitly give 'sh' or it won't run
    print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_pcre2_config.t, have $version = }, Dumper($version), "\n\n";
    cmp_ok((scalar @{$version}), '==', 1, 'Command `pcre2-config --version` executes with 1 line of output');

    my $version_0 = $version->[0];
    print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_pcre2_config.t, have $version_0 = '}, $version_0, q{'}, "\n\n";
    ok(defined $version_0, 'Command `pcre2-config --version` 1 line of output is defined');
    ok($version_0 =~ m/^([\d\.]+)(?:-DEV)?$/xms, 'Command `pcre2-config --version` 1 line of output is valid');  # match both stable & dev versions

    my $version_split = [split /[.]/, $1];
    print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_pcre2_config.t, have $version_split = }, Dumper($version_split), "\n\n";
    my $version_split_0 = $version_split->[0] + 0;
    print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_pcre2_config.t, have $version_split_0 = '}, $version_split_0, q{'}, "\n\n";
    cmp_ok($version_split_0, '>=', 10, 'Command `pcre2-config --version` returns major version 10 or newer');


    SKIP: {
        skip 'Major version greater than 10 does not require minor version check', 1 if ($version_split_0 != 10);
        my $version_split_1 = $version_split->[1] + 0;
        cmp_ok($version_split_1, '>=', 23, 'Command `pcre2-config --version` returns minor version 23 or newer');
    }

    # run `pcre2-config --cflags`, check for valid output
    my $cflags = [ split /\r?\n/, capture_merged { system $sh_path . q{ } . $pcre2_path . ' --cflags'; }];  # WINDOWS HACK: must explicitly give 'sh' or it won't run
    print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_pcre2_config.t, have $cflags = }, Dumper($cflags), "\n\n";

    SKIP: {
        skip 'System install may not necessarily set cflags', 4 if (Alien::PCRE2->install_type() eq 'system');

        cmp_ok((scalar @{$cflags}), '==', 1, 'Command `pcre2-config --cflags` executes with 1 line of output');

        my $cflags_0 = $cflags->[0];
        print {*STDERR} "\n\n", q{<<< DEBUG >>> in t/02_pcre2_config.t, have $cflags_0 = '}, $cflags_0, q{'}, "\n\n";
        ok(defined $cflags_0, 'Command `pcre2-config --cflags` 1 line of output is defined');
        is((substr $cflags_0, 0, 2), '-I', 'Command `pcre2-config --cflags` 1 line of output starts correctly');
        if ($OSNAME eq 'MSWin32') {
            ok($cflags_0 =~ m/([\w\.\-\s\\\:]+)$/xms, 'Command `pcre2-config --cflags` 1 line of output is valid');  # match -IC:\dang_windows\paths\ -ID:\drive_letters\as.well
        }
        else {
            ok($cflags_0 =~ m/([\w\.\-\s\/]+)$/xms, 'Command `pcre2-config --cflags` 1 line of output is valid');  # match -I/some_path/to.somewhere/ -I/and/another
        }
    }
}
 
done_testing;
