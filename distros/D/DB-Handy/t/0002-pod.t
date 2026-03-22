# POD syntax check.
# Runs only when TEST_AUTHOR=1 is set; always skipped on CPAN Testers.
use strict;
use FindBin ();
use lib "$FindBin::Bin/../lib";

# ---- Minimal test harness (no Test::More required) --------------------
my ($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);
sub plan_tests { $T_PLAN = $_[0]; print "1..$T_PLAN\n" }
sub plan_skip  { print "1..0 # SKIP $_[0]\n"; exit 0 }
sub ok   { my($ok,$n)=@_; $T_RUN++; $ok||$T_FAIL++;
           print +($ok?'':'not ')."ok $T_RUN".($n?" - $n":"")."\n"; $ok }
END { exit 1 if $T_PLAN && $T_FAIL }
# -----------------------------------------------------------------------

# Run only in author environment.
plan_skip('Set TEST_AUTHOR=1 to run POD tests') unless $ENV{TEST_AUTHOR};

# Skip gracefully if Test::Pod is not installed.
eval { require Test::Pod; Test::Pod->import };
plan_skip('Test::Pod not installed') if $@;

# Delegate TAP output to Test::Pod's all_pod_files_ok().
all_pod_files_ok();

