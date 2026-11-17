use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp ();
use IPC::Open3 ();

# OFFLINE test of t/lib/LibpqEnglish.pm on a perl whose POSIX does not know
# LC_MESSAGES.
#
# WHY: on Windows POSIX::LC_MESSAGES() dies with "Your vendor has not defined
# POSIX macro LC_MESSAGES". The helper called it in a BEGIN block, so every
# file that loads the helper died before its first test, whatever it was
# about. The helper must go on without the constant and work through the
# environment (LC_ALL and LC_MESSAGES set to C, LANGUAGE gone), which is what
# a child process inherits.
#
# What this file claims:
#   1. with POSIX::LC_MESSAGES undefined (the real message) the helper loads,
#      and the environment is C for messages, LANGUAGE gone;
#   2. with the constant present setlocale is called with it and 'C', as before.
#
# WHAT RUNS FOR REAL: the helper, in a perl of its own.
# THE SUBSTITUTION: POSIX::LC_MESSAGES / POSIX::setlocale in that child -- the
# platform that lacks the constant is not here.

my $LIB = "$FindBin::Bin/lib";

# The child is a file in a directory of its own, started in list form without
# a quote, space or line break in any argument: Windows has no list-form pipe
# open and splits a -e program at its spaces. The library path is a literal of
# that file, so a space in it does not reach the command line either.
my $TMP = File::Temp->newdir;
my $N   = 0;

sub run_child {
  my ($prelude) = @_;
  (my $lib = $LIB) =~ s/([\\'])/\\$1/g;
  my $code = "use lib '$lib';\n" . $prelude . q{
    BEGIN { $ENV{LANGUAGE} = 'de'; $ENV{LC_ALL} = 'de_DE.UTF-8'; $ENV{LC_MESSAGES} = 'de_DE.UTF-8' }
    use LibpqEnglish;
    print "LC_ALL=$ENV{LC_ALL}\nLC_MESSAGES=$ENV{LC_MESSAGES}\nLANGUAGE=", (exists $ENV{LANGUAGE} ? $ENV{LANGUAGE} : '<gone>'), "\n";
  };
  my $file = "$TMP/child-" . ++$N . '.pl';
  open my $w, '>', $file or die "cannot write $file: $!";
  binmode $w;
  print $w $code;
  close $w or die "cannot write $file: $!";
  my $pid = IPC::Open3::open3(my $in, my $fh, undef, $^X, $file);
  close $in;
  my $out = do { local $/; <$fh> };
  waitpid $pid, 0;
  $out =~ s/\r\n/\n/g;    # a pipe is text on Windows: its lines end in CRLF
  return ($? >> 8, $out);
}

{
  my ($exit, $out) = run_child(q{
    use POSIX ();
    BEGIN {
      no warnings 'redefine';
      *POSIX::LC_MESSAGES = sub { die "Your vendor has not defined POSIX macro LC_MESSAGES, used at x\n" };
    }
  });
  is $exit, 0, 'POSIX knows no LC_MESSAGES: the helper loads';
  like $out, qr/^LC_ALL=C$/m,           '... LC_ALL is C';
  like $out, qr/^LC_MESSAGES=C$/m,      '... LC_MESSAGES is C';
  like $out, qr/^LANGUAGE=<gone>$/m,    '... LANGUAGE is gone';
}

{
  my ($exit, $out) = run_child(q{
    use POSIX ();
    our @CALLS;
    BEGIN {
      no warnings 'redefine';
      *POSIX::LC_MESSAGES = sub () { 'the-constant' };
      *POSIX::setlocale   = sub { push @CALLS, [@_]; 'C' };
    }
    END { print "setlocale(@$_)\n" for @CALLS }
  });
  is $exit, 0, 'POSIX knows LC_MESSAGES: the helper loads';
  like $out, qr/^setlocale\(the-constant C\)$/m, '... and sets the locale of the messages to C';
  like $out, qr/^LC_ALL=C$/m,        '... and the environment is C as well';
  like $out, qr/^LANGUAGE=<gone>$/m, '... LANGUAGE is gone';
}

done_testing;
