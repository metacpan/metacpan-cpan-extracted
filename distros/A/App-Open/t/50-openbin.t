#===============================================================================
#
#         FILE:  50-openbin.t
#
#  DESCRIPTION:  Tests bin/open and the execute_program() functionality of App::Open.
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Erik Hollensbe (), <erik@hollensbe.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  06/03/2008 03:43:36 AM PDT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use POSIX qw(WEXITSTATUS);

use constant DEBUG => 0;

BEGIN { 
    # our tests rely on the fact that we can execute perl against them. Use the
    # perl executing this test suite to run the open program. See the execute()
    # subroutine for more information.
    
    require Test::More;
    if (WEXITSTATUS(system($^X, "-e", "exit 1"))) {
        Test::More->import('no_plan');
        Test::More::diag("Generating exit_1 test script in t/resource/helpers...");
        my ($in, $out);
        open($in, 't/resource/helpers/exit_1.tmpl') && do {
            open($out, '>', 't/resource/helpers/exit_1') && do {
                local $/ = undef;
                my $contents = <$in>;
                $contents =~ s/^\@PERL\@/#!$^X/sg;
                print { $out } $contents;
                close($out);
                chmod(0700, 't/resource/helpers/exit_1');
            };
            close($in);
        };
    } else {
        Test::More->import('skip_all' => "Couldn't execute this perl!");
    }
};

# XXX this might change as the test fills out and configuration needs change
#     for each assertion.
my @config_args = qw(-c t/resource/configs/openbin1.yaml);

sub execute {
    local $/ = undef;
    my ($status, $output);

    my @command_line = ($^X, qw(-I lib bin/openit), @config_args, @_);

    if (DEBUG) {
        diag "Executing '@command_line'";
    }

    open(FH, "-|", @command_line) && do {
        $output = <FH>;
        # temporary use to verify we opened successfully, since we can't record
        # $? until the filehandle closes.
        $status = 1; 
        close(FH);
    };

    $status = WEXITSTATUS($?) if ($status);
    return ($status, $output);
}

my ($status, $output);

($status, $output) = execute("t/resource/dummy_files/foo.tar.gz");

is($status, 0);
is($output, "Hello, world!\n");

($status, $output) = execute("t/resource/dummy_files/bar.rpm.spec.gz");

is($status, 0);
is($output, "Monkeys!\n");

#
# Create a temporary file and use open to delete it, 'rm' associated with the
# 'test' extension.
#

my $test_file = "t/resource/dummy_files/quux.test";

ok(open(FH, ">$test_file"));
ok(close(FH));

fail("Cannot create files in this test suite") unless (-e $test_file);

($status, $output) = execute($test_file);

ok(!-e $test_file);
is($status, 0);
is($output, "");

#
# test with multiple files
#

($status, $output) = execute(qw(t/resource/dummy_files/foo.tar.gz t/resource/dummy_files/bar.rpm.spec.gz));
is($status, 0);
is($output, "Hello, world!\nMonkeys!\n");

#
# Test exit propogation (one file, should be propogated to the shell)
#

($status, $output) = execute("t/resource/dummy_files/test.exit");
is($status, 1);
is($output, "Exiting with an error code of 1\n");

#
# Test exit propogation (multiple files, should exit 0 if all files were processed)
#

($status, $output) = execute(qw(t/resource/dummy_files/test.exit t/resource/dummy_files/foo.tar.gz t/resource/dummy_files/bar.rpm.spec.gz));
is($status, 0);
is($output, "Exiting with an error code of 1\nHello, world!\nMonkeys!\n");

#
# Test URLs
#

($status, $output) = execute("http://example.com");
is($status, 0);
is($output, "http://example.com\n");
