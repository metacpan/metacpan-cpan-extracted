#!/usr/bin/env perl
# t/05-child-perl.t -- the helper that starts a second perl for the tests
# (t/lib/ChildPerl.pm).
#
# WHY this matters: the second-process tests (t/47, t/51, t/58, t/68) used to
# pass their program to `perl -e`. Where the command line goes through
# cmd.exe, a program of several lines with quotes is cut at the first line
# break and the quotes are read by the shell: the child dies with a syntax
# error at -e line 1 before it has done anything. The helper writes the
# program to a file and starts perl in list form, so the program and its
# arguments arrive as they were written. This file pins exactly that: the
# program text, the arguments, the exit code and the output come through.
# Under Windows perl builds the command line of a list-form system() itself and
# leaves an argument with a double quote in it raw; ChildPerl quotes such
# arguments for the C runtime first (modelled at the end, as Linux has no such
# command line).

use strict;
use warnings;
use lib 't/lib';
use Test::More;
use ChildPerl;

# Several lines, single and double quotes, a heredoc, a comment: everything a
# shell would cut or re-read.
my $PROGRAM = <<'EOP';
use strict;
use warnings;
# a comment line, then quotes of both kinds
my $single = 'it is "quoted" twice';
my $double = "and 'again'";
print "$single\n$double\n";
print "arg: $_\n" for @ARGV;
print <<"TXT";
heredoc line with a \$ and a "quote"
TXT
exit 7;
EOP

my @args = ('plain', 'two words', q{it's "mixed"}, '');

my @lines = capture_child_perl($PROGRAM, @args);
my $status = $?;

is_deeply \@lines, [
  qq{it is "quoted" twice\n},
  qq{and 'again'\n},
  "arg: plain\n",
  "arg: two words\n",
  qq{arg: it's "mixed"\n},
  "arg: \n",
  qq{heredoc line with a \$ and a "quote"\n},
], 'a program of several lines with both kinds of quotes arrives unchanged, with its arguments, and its stdout comes back';

is $status >> 8, 7, 'the exit code of the child is in $? after capture_child_perl';

my $rc = run_child_perl(q{exit 5}, 'unused');
isnt $rc, -1, 'run_child_perl started the process';
is $rc >> 8, 5, 'run_child_perl answers system()s wait status: the exit code is in it';

is child_perl_file($PROGRAM), child_perl_file($PROGRAM),
  'one program text is written to one file';
ok -f child_perl_file($PROGRAM), 'the program file exists';
isnt child_perl_file($PROGRAM), child_perl_file(q{exit 0}),
  'another program text is another file';

# The child sees the @INC of this process: a directory given here is found.
{
  my $dir = 't/lib';
  my @seen = capture_child_perl(q{print "$_\n" for grep { !ref } @INC});
  chomp @seen;
  ok scalar(grep { $_ eq $dir } @seen), "the child's \@INC carries this process's directories";
}

# The Windows chain, modelled. Linux hands argv to the child directly, so the
# case cannot be run here; both halves of the chain are written out instead.
#
# win32.c create_command_line (perl 5.20 to 5.42), for a program that is not
# a shell: an argument is wrapped in quotes only when it is empty, or has
# whitespace and no `"` at all; one with a `"` stays raw (no escaping); one
# that starts and ends with `"` (length > 1) is left alone.
sub perl_command_line {
  my @args = @_;
  return join ' ', map {
    my $a = $_;
    if (length $a == 0) { '""' }
    elsif (length $a > 1 && $a =~ /\A".*"\z/s) { $a }
    elsif ($a !~ /"/ && $a =~ /\s/) { qq{"$a"} }
    else { $a }
  } @args;
}

# The C runtime's split of that line (CommandLineToArgvW rules): 2n
# backslashes before `"` are n backslashes and the quote toggles quoting,
# 2n+1 are n backslashes and a literal `"`; backslashes elsewhere are
# literal; whitespace outside quotes separates; `""` is an empty argument.
sub crt_split {
  my ($line) = @_;
  my (@argv, $cur, $in);
  my @c = split //, $line;
  while (@c) {
    my $c = shift @c;
    if ($c eq '\\') {
      my $n = 1;
      $n++, shift @c while @c && $c[0] eq '\\';
      if (@c && $c[0] eq '"') {
        shift @c;
        $cur = ($cur // '') . '\\' x int($n / 2);
        if ($n % 2) { $cur .= '"' } else { $in = !$in }
      }
      else { $cur = ($cur // '') . '\\' x $n }
    }
    elsif ($c eq '"') { $in = !$in; $cur //= '' }
    elsif ($c =~ /\s/ && !$in) { push @argv, $cur if defined $cur; undef $cur }
    else { $cur = ($cur // '') . $c }
  }
  push @argv, $cur if defined $cur;
  return @argv;
}

my @tricky = ('plain', 'two words', q{it's "mixed"}, '', q{back\\}, q{back\\ slash},
  q{q\\"x}, q{ends in "}, q{"fully quoted"});

isnt join("\0", crt_split(perl_command_line(@tricky))), join("\0", @tricky),
  'windows model: arguments handed to the command line raw do not reach the child unchanged';
is_deeply [crt_split(perl_command_line(q{it's "mixed"}))], [q{it's}, 'mixed'],
  'windows model: it\'s "mixed" arrives as two arguments';

is_deeply [crt_split(perl_command_line(map { ChildPerl::quote_win32_arg($_) } @tricky))], \@tricky,
  'windows model: arguments quoted by ChildPerl::quote_win32_arg reach the child unchanged';

done_testing;
