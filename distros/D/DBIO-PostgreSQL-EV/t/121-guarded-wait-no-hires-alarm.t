use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp ();
use IPC::Open3 ();

alarm 120;

# t/79-guarded-wait.t on a platform with no Time::HiRes::alarm.
#
# Where Time::HiRes has no timer of fractions (Windows: Time::HiRes::alarm
# croaks "unimplemented in this platform") t/79 has nothing to measure and
# has to skip as a whole, not die at its first alarm. Simulated here: a child
# perl whose Time::HiRes::alarm croaks, as on that platform, runs t/79; the
# file runs the same on every host.

my $T79 = "$FindBin::Bin/79-guarded-wait.t";
ok -f $T79, 't/79-guarded-wait.t found';

# The child's program goes to a file, not into a -e argument, and the child is
# started from a list without a shell. On Windows perl builds the child's
# command line itself (win32.c create_command_line): an argument with a quote
# is not put in quotes and the quote is not escaped, so an argument with
# spaces AND a quote (a multi-line -e program) is split into several
# arguments by the child -- it runs nothing, writes nothing, exits 0. And
# perl 5.20 on Windows has no list form of a pipe open (open '-|', @list).
my $dir  = File::Temp->newdir;
my $prog = "$dir/child.pl";
open my $pfh, '>', $prog or BAIL_OUT("cannot write $prog: $!");
print $pfh <<'CHILD';
BEGIN {
  require Time::HiRes;
  no warnings 'redefine';
  *Time::HiRes::alarm = sub { die "Time::HiRes::alarm(): unimplemented in this platform\n" };
}
do $ARGV[0]; print STDERR "t/79 failed: $@" if $@;
exit 0;
CHILD
close $pfh or BAIL_OUT("cannot write $prog: $!");

my @cmd = ($^X, (map { "-I$_" } @INC), $prog, $T79);

ok !(grep { /["\r\n]/ } @cmd),
  'no argument of the child command line holds a quote or a line break (win32 create_command_line splits it)';

my $pid = IPC::Open3::open3(my $in, my $fh, '>&STDERR', @cmd);
close $in;
my $out = do { local $/; scalar <$fh> };
$out = '' unless defined $out;
waitpid $pid, 0;
my $status = $?;
$out =~ s/\r\n/\n/g;

is $status, 0, 't/79 exits 0 where Time::HiRes::alarm croaks';
like $out, qr/\A1\.\.0 # SKIP /, '... and skips as a whole';
unlike $out, qr/\bdied\b|unimplemented|^not ok/m, '... without an error or a failed test';

done_testing;
