use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp ();
use IPC::Open3 ();
use POSIX ();

alarm 120;

# t/lib/LibpqCLocale.pm on a platform with no POSIX::LC_MESSAGES.
#
# Windows has no such constant: POSIX::LC_MESSAGES() dies "Your vendor has not
# defined POSIX macro LC_MESSAGES". The helper loaded by t/119, 122, 33, 34,
# 53, 63, 64, 65, 67 and 86 must still load there, or each of those files dies
# at its first line -- also the live ones that would skip without a DSN. On
# that platform libpq sets no locale of its own (it asks libintl, which reads
# LANGUAGE / LC_ALL / LC_MESSAGES / LANG), so the environment is the way to C
# there, and the helper sets it whether or not setlocale can be called.
#
# Simulated here: a child perl, in which POSIX::LC_MESSAGES dies with exactly
# that message before anything is loaded, loads the helper -- and t/119 --
# the same on every host. The child's program goes to a file and the child is
# started from a list (IPC::Open3): on Windows a -e program with quotes and
# newlines is split by the child's command line (see t/121).

my $LIB  = "$FindBin::Bin/lib";
my $T119 = "$FindBin::Bin/119-error-values-live.t";
ok -f $T119, 't/119-error-values-live.t found';

my $dir  = File::Temp->newdir;
my $prog = "$dir/child.pl";
open my $pfh, '>', $prog or BAIL_OUT("cannot write $prog: $!");
print $pfh <<'CHILD';
use strict;
use warnings;
my ($mode, $file) = @ARGV;
my $real;
BEGIN {
  require POSIX;
  $real = eval { POSIX::LC_MESSAGES() };
  no warnings;
  unless ($ARGV[0] eq q{real}) {
    *POSIX::LC_MESSAGES = sub {
      die "Your vendor has not defined POSIX macro LC_MESSAGES, used at $0 line 1\n";
    };
  }
  # FindBin (t/119) reads $0 when it loads
  $0 = $ARGV[1] if $ARGV[0] eq 'file';
}
if ($mode eq q{helper} or $mode eq q{real}) {
  require LibpqCLocale;
  print "LC_ALL=", (defined $ENV{LC_ALL} ? $ENV{LC_ALL} : '<unset>'), "\n";
  print "LANGUAGE=", (exists $ENV{LANGUAGE} ? 'set' : 'unset'), "\n";
  print "LC_MESSAGES=", (exists $ENV{LC_MESSAGES} ? 'set' : 'unset'), "\n";
  print "SETLOCALE=", (defined $real ? POSIX::setlocale($real) : ''), "\n";
  exit 0;
}
do $file;
if ($@) { print STDERR "child: $@"; exit 1 }
exit 0;
CHILD
close $pfh or BAIL_OUT("cannot write $prog: $!");

# The child as the Windows CRT sees it: no quote, no newline in an argument.
sub run_child {
  my @args = @_;
  my @cmd = ($^X, (map { "-I$_" } grep { !ref } @INC), "-I$LIB", $prog, @args);
  my $pid = IPC::Open3::open3(my $in, my $out, '>&STDERR', @cmd);
  close $in;
  my $output = do { local $/; <$out> };
  $output = '' unless defined $output;
  waitpid $pid, 0;
  $output =~ s/\r\n/\n/g;
  return ($output, $? >> 8);
}

{
  local $ENV{LC_ALL}      = 'de_DE.UTF-8';
  local $ENV{LANGUAGE}    = 'de';
  local $ENV{LC_MESSAGES} = 'de_DE.UTF-8';
  my ($out, $exit) = run_child(helper => '');
  is $exit, 0, 'the helper loads where POSIX::LC_MESSAGES dies';
  like $out, qr/^LC_ALL=C$/m, '... puts LC_ALL to C in the environment';
  like $out, qr/^LANGUAGE=unset$/m, '... drops LANGUAGE';
  like $out, qr/^LC_MESSAGES=unset$/m, '... and drops LC_MESSAGES';

}

# Where the constant exists the helper still calls setlocale: the process was
# started under de_DE, a child with the real constant ends in C.
SKIP: {
  skip q{this host has no POSIX::LC_MESSAGES either; nothing to call setlocale with}, 1
    unless defined eval { POSIX::LC_MESSAGES() };
  local $ENV{LC_ALL} = q{de_DE.UTF-8};
  my ($out) = run_child(real => q{});
  like $out, qr/^SETLOCALE=C$/m, q{the helper sets the message locale of the process to C where the constant exists};
}

{
  delete local @ENV{ grep { /^DBIO_TEST_/ } keys %ENV };
  my ($out, $exit) = run_child(file => $T119);
  is $exit, 0, 't/119 exits 0 where POSIX::LC_MESSAGES dies, with no database named';
  like $out, qr/\A1\.\.0 # SKIP /, '... and skips as a whole';
}

done_testing;
