# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Apache::Test qw(plan ok have_lwp);
use Apache::TestRequest qw(GET);
use Apache::TestUtil qw(t_cmp);

#plan tests => 3, have_lwp;
print "1..0 # skipped: Test not yet implemented.\n";
exit;

# Basic request
my $bad_file_msg    = 'bad.par does not seem to be a valid PAR (Zip) file. Skipping.';
my $no_par_file_msg = 'PARFile doesn\'t exist: ';
my $no_par_dir_msg  = 'PARDir doesn\'t exist: ';
my $log_contents = '';

open my $fh, 't/error_log' or die "Unable to open error_log, aborting.";
{
	local $/;
	$log_contents=<$fh>;
}
close $fh;
ok( ($log_contents =~ /\Q$bad_file_msg\E$/m) ? 1 : 0);
# This should be fixed, since we dont actually have the script name expected
ok( ($log_contents =~ /^\Q$no_par_file_msg\E.*?not_found.par$/m) ? 1 : 0);
ok( ($log_contents =~ /^\Q$no_par_dir_msg\E.*?not_dir$/m) ? 1 : 0);

