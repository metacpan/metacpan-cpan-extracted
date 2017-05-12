package My::ModuleBuild;
use strict;
use warnings;
our $VERSION = 0.023_000;

use Alien::Base::ModuleBuild;
use base qw( Alien::Base::ModuleBuild );

use File::chdir;
use Capture::Tiny qw( capture_merged );
use Data::Dumper;
use IPC::Cmd qw(can_run);
use English qw(-no_match_vars);  # for $CHILD_ERROR & $OSNAME
use Env qw( @PATH );

sub alien_check_installed_version {
    # check if `astyle` can be run, if so get path to binary executable
    my $astyle_path = undef;
#    print {*STDERR} '<<< DEBUG >>>: in ModuleBuild::alien_check_installed_version(), have $OSNAME = ', $OSNAME, "\n";
    if ($OSNAME eq 'MSWin32') {
        $astyle_path = can_run('AStyle.exe');
    }
    else {
        $astyle_path = can_run('astyle');
    }

    if (not defined $astyle_path) {
#        print {*STDERR} '<<< DEBUG >>>: in ModuleBuild::alien_check_installed_version(), no `astyle` binary found, returning nothing', "\n";
        return;
    }

#    print {*STDERR} '<<< DEBUG >>>: in ModuleBuild::alien_check_installed_version(), have $astyle_path = ', q{'}, $astyle_path, q{'}, "\n";

    # run `astyle --version`, check for valid output
    my $version = [split /\r?\n/, capture_merged { system "$astyle_path --version"; }];
    if($CHILD_ERROR != 0) {
        print {*STDERR} 'WARNING WAAMBIV00: Alien::astyle experienced an error while attempting to determine installed version...', 
            "\n", Dumper($version), "\n", 'Trying to continue...', "\n";
    }
    if ((scalar @{$version}) > 1) {
        print {*STDERR} 'WARNING WAAMBIV01: Alien::astyle received too much output while attempting to determine installed version...', 
            "\n", Dumper($version), "\n", 'Trying to continue...', "\n";
    }

#    print {*STDERR} '<<< DEBUG >>>: in ModuleBuild::alien_check_installed_version(), have $version = ', Dumper($version), "\n";
    my $version_0 = $version->[0];
    if ((defined $version_0) and
        ((substr $version_0, 0, 22) eq 'Artistic Style Version') and 
        ($version_0 =~ m/([\d\.]+)$/xms)) {
        my $version = $1;
#        print {*STDERR} '<<< DEBUG >>>: in ModuleBuild::alien_check_installed_version(), returning $version = ', $version, "\n";
        return $version;
    }
    else {
#        print {*STDERR} '<<< DEBUG >>>: in ModuleBuild::alien_check_installed_version(), returning nothing', "\n";
        return;
    }
}

sub alien_check_built_version {
    my $lower_directory = $CWD[-1];
    if ($lower_directory =~ /^astyle-(.*)$/) {
        return $1;
    }
    else {
        return 'unknown';
    }
}

1;
