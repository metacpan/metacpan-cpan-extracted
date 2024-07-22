package App::ArduinoBuilder::System;

use strict;
use warnings;
use utf8;

use Cwd;
use Exporter 'import';
use File::Spec::Functions 'catdir', 'rel2abs', 'canonpath';
use List::Util 'first';
use Log::Any::Simple ':default';
use Win32::ShellQuote 'quote_native';

our @EXPORT_OK = qw(find_arduino_dir system_cwd system_canonpath execute_cmd split_cmd);

sub find_arduino_dir {
  my @tests;
  if ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys') {
    if (exists $ENV{LOCALAPPDATA}) {
      push @tests, catdir($ENV{LOCALAPPDATA}, 'Arduino15');
    }
  }
  if ($^O ne 'MSWin32') {
    push @tests, '/usr/share/arduino', '/usr/local/share/arduino';
    if (`which arduino 2>/dev/null` =~ m{^(.*)/bin/arduino}) {
      push @tests, catdir($1, 'share/arduino');
    }
  }
  return first { -d } @tests;
}

sub system_cwd {
  my $cwd = getcwd();
  # Todo: we could have a "use_native_cygwin" option somewhere in the improbable
  # case of a native toolchain to deactivate this logic (as well as using
  # /dev/null insted of nul in the builder).
  if ($^O eq 'cygwin') {
    $cwd = `cygpath -w '${cwd}'`;
    chomp($cwd);
  }
  return $cwd;
}

# Canonicalize a file path to be used to compare file paths (can’t be fed to
# external utilities).
sub system_canonpath {
  my ($path) = @_;
  my $canon = canonpath(rel2abs($path));
  if ($^O eq 'cygwin') {
    $canon = `cygpath '$canon'`;
    chomp($canon);
  }
  return $canon;
}

# Splits a given command line string into individual arguments.
# Returns the array of individual arguments.
#
# This approach is very primitive. However both Parse::CommandLine and
# Text::ParseWords have the same issue that they consider that a backslash can
# escape any character, which is wrong on Windows (C:\foo is not C:foo).
# Also Text::Balanced, is not well suited for this case where we can have
# unquoted pieces of text.
#
# Ideally, we would use whatever Perl uses to split a command into word as
# per https://perldoc.perl.org/functions/exec, but this does not seem to be
# exposed
#
# TODO: support escaped quotes (that are not quoting arguments) as well as,
# maybe, quotes interrupting unquoted arguments.
sub split_cmd {
  my ($cmd) = @_;
  my @cmd;
  while ($cmd =~ m/ \G \s* (?: (['"])(?<p>.*?)\1 | (?<p>[^ ]+) ) /gx) {
    push @cmd, $+{p};
  }
  return @cmd;
}

sub execute_cmd {
  my ($cmd, %options) = @_;
  trace $cmd;
  if ($^O eq 'MSWin32') {
    # This fix cases where the command looks like: foo '--bar="baz"'
    #
    # TODO: Possibly we could just split the command using split_cmd
    # and then pass the list to system (and find something for the `` case).
    $cmd = quote_native(split_cmd($cmd));
  }
  my $failed;
  if (exists $options{capture_output}) {
    my $out = `${cmd}`;
    if (defined $out) {
      ${$options{capture_output}} = $out;
    } else {
      $failed = 1;
    }
  } else {
    $failed = system($cmd);
  }
  if ($failed) {
    debug "Can’t execute the following command: $!\n\t${cmd}";
    fatal "External command failed";
  }
  return 1;
}
