use strict;
use warnings;
use lib::relative '.';
use TestKit;

use Capture::Tiny qw(capture);
use File::Basename ();
use List::Util qw(first);
use Path::Class;

# Test script/git-find invocation.  This is mostly for coverage.
sub test_invocations {

    # Check if we are running under cover(1) from Devel::Cover
    my $is_covering = !!(eval 'Devel::Cover::get_coverage()');
    diag $is_covering ? 'Devel::Cover running' : 'Devel::Cover not covering';

    # Find the right script/prt for this test run.
    my $running_in_blib = defined first { /\bblib\b/ } @INC;
    my $dir = dir(File::Basename::dirname(__FILE__));
    my $script = $dir->parent->file(
                    ($running_in_blib ? qw(blib) : ()), qw(script git-find)
                )->absolute;

    # Make the command to run script/prt.
    my @cmd = ($^X, $is_covering ? ('-MDevel::Cover=-silent,1') : ());

    push @cmd, (map { "-I$_" } @INC);
        # brute-force our @INC down to the other perl invocation
        # so that we can run tests with -Ilib.

    push @cmd, $script;
    diag "Testing script/git-find with command line:\n", join ' ', @cmd;

    # Run the tests

    my ($stdout, $stderr, $exit) = capture {
        return system(@cmd, '-h');
    };
    cmp_ok $exit>>8, '==', 0, 'exit code -h';
}

test_invocations;
done_testing;
