package ChildPerl;
# A second perl process for a test, started from a script FILE in list form.
#
# WHY a file: the tests that need a process of their own (a file lock seen
# from outside, a scenario that may crash) used to hand the program to
# `perl -e`. A program of several lines, with quotes in it, does not survive
# that where the command goes through cmd.exe (Windows): the shell cuts it at
# the first line break and reads the quotes its own way. A file named in a
# list-form system() never meets a shell, so the program arrives as
# written, on every platform.
#
# capture_child_perl does not read the child through a pipe open either: the
# list form of a pipe open is not implemented by perl before 5.22 on Windows.
# It points stdout at a temporary file, runs the child with the list-form
# system(), and reads the file.
use strict;
use warnings;
use File::Temp ();
use Exporter 'import';

our @EXPORT = qw(child_perl_file run_child_perl capture_child_perl);

# program text => File::Temp object; one file per text, removed at exit.
my %FILE;

# The path of a script file holding $program.
sub child_perl_file {
  my ($program) = @_;
  $FILE{$program} ||= do {
    my $fh = File::Temp->new(SUFFIX => '.pl', UNLINK => 1);
    print {$fh} $program or die "cannot write the child program: $!";
    close $fh or die "cannot write the child program: $!";
    $fh;
  };
  return $FILE{$program}->filename;
}

# perl, with this process's @INC, running the file: the same modules load
# whether the suite runs under prove -l or against a build.
#
# Under Windows every argument after the program is quoted for the C runtime
# first (quote_win32_arg); $^X stays raw, perl quotes it itself and it serves
# the CreateProcess lookup.
sub _command {
  my ($program, @args) = @_;
  my @rest = ((map { "-I$_" } grep { !ref } @INC), child_perl_file($program), @args);
  @rest = map { quote_win32_arg($_) } @rest if $^O eq 'MSWin32';
  return ($^X, @rest);
}

# WHY: win32/win32.c, create_command_line (perl 5.20 to 5.42), builds the
# command line of a list-form system() itself. It wraps an argument in quotes
# only if it is empty, or has whitespace and no `"`; an argument with a `"`
# stays raw, so the C runtime of the child splits `it's "mixed"` into two
# arguments. An argument that starts and ends with `"` is left untouched, so
# one quoted here by the CommandLineToArgvW rules (backslashes before a `"`
# doubled, the `"` escaped, trailing backslashes doubled, all in `"..."`)
# reaches the child as written. Linux (execvp) needs none of this.
sub quote_win32_arg {
  my ($arg) = @_;
  $arg =~ s/(\\*)"/$1$1\\"/g;
  $arg =~ s/(\\+)$/$1$1/;
  return qq{"$arg"};
}

# system()'s answer: -1 where the process did not start (the caller checks),
# else the wait status.
sub run_child_perl {
  return system _command(@_);
}

# The lines the process printed to stdout; $? holds its wait status after.
sub capture_child_perl {
  my @cmd = _command(@_);
  my $out = File::Temp->new(UNLINK => 1);
  close $out or die "cannot run the child process: $!";

  # flush first: buffered output would otherwise land in the child's file
  STDOUT->flush;
  open my $saved, '>&', \*STDOUT or die "cannot run the child process: $!";
  open STDOUT, '>', $out->filename or die "cannot run the child process: $!";
  my $rc = system @cmd;
  my $err = "$!";
  my $status = $?;
  close STDOUT;
  open STDOUT, '>&', $saved or die "cannot restore stdout: $!";
  close $saved;

  die "cannot run the child process: $err" if $rc == -1;

  open my $fh, '<', $out->filename or die "cannot read the child output: $!";
  my @lines = <$fh>;
  close $fh;
  $? = $status;
  return @lines;
}

1;
