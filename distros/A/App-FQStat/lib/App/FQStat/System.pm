
package App::FQStat::System;
# App::FQStat is (c) 2007-2009 Steffen Mueller
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;
use App::FQStat::Debug;
use App::FQStat::Config qw/get_config/;
use String::ShellQuote ();

use base 'Exporter';
our %EXPORT_TAGS = (
  'all' => [qw(
    exec_local
    run
    run_local
    run_capture
    run_local_capture
  )],
);
our @EXPORT_OK = @{$EXPORT_TAGS{'all'}};

sub exec_local {
  warnenter if ::DEBUG;
  warnline "Switching to running '@_' locally." if ::DEBUG > 1;
  return exec(@_);
}

sub run_local {
  warnenter if ::DEBUG;
  warnline "Running '@_' locally." if ::DEBUG > 1;
  return system(@_);
}

sub run_local_capture {
  warnenter if ::DEBUG;
  warnline "Running '@_' locally, capturing." if ::DEBUG > 1;
  my $cmd = String::ShellQuote::shell_quote(@_);
  return `$cmd`;
}

sub run {
  warnenter if ::DEBUG;
  warnline "Running '@_'." if ::DEBUG > 1;
  my $cmd = _make_system_call(@_);
  return system($cmd);
}

sub run_capture {
  warnenter if ::DEBUG;
  warnline "Running '@_' capturing." if ::DEBUG > 1;
  my $cmd = _make_system_call(@_);
  return `$cmd`;
}

sub _make_system_call {
  warnenter if ::DEBUG > 1;
  my $ssh = get_config("sshcommand");

  my $cmd = String::ShellQuote::shell_quote(@_);
  if (defined $ssh and not $ssh eq '') {
    if ($ssh =~ s/!COMMAND!/$cmd/g) {
      $cmd = $ssh;
    }
    else {
      $cmd = "$ssh $cmd";
    }
  }

  warnline "Generated shell commannd '$cmd'." if ::DEBUG > 1;
  return $cmd;
}


# lifted and modified from Module::Install::Can ((c) Brian Ingerson, Audrey Tang, Adam Kennedy, et al)
# check if we can run some command
sub module_install_can_run {
  warnenter if ::DEBUG;
  my $cmd = shift;
  my $ssh = get_config("sshcommand");
  require ExtUtils::MakeMaker;
  require Config;
  require File::Spec;
  my $_cmd = $cmd;
  if (defined $ssh and $ssh ne '') {
# too slow...
    return $_cmd; # err, right!
#    my $cmd_escape = $cmd;
#    $cmd_escape =~ s/'/\\'g/; # bad
#    my $problem = run(
#      'perl', '-e',
#      q|use ExtUtils::MakeMaker; if(-x '|
#        . $cmd_escape 
#        . q|' or MM->maybe_command('|
#        . $cmd_escape
#        . q|'){exit(0)}else{exit(1)}|
#    );
#    return $_cmd unless $problem;

  }
  else {
    return $_cmd if (-x $_cmd or $_cmd = MM->maybe_command($_cmd));
    for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
      my $abs = File::Spec->catfile($dir, $cmd);
      return $abs if (-x $abs or $abs = MM->maybe_command($abs));
    }
  }

  return;
}



1;


