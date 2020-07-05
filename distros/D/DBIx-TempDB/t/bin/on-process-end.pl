#!/usr/bin/env perl
use DBIx::TempDB::Util 'on_process_end';

my $mode = shift @ARGV || 'destroy';
my $pid  = $$;
my $ppid = getppid;

warn "# [$pid] on-process-end.pl $mode started\n" if $ENV{HARNESS_IS_VERBOSE};

my $guard = on_process_end $mode => sub {
  open my $FH, '>>', $ENV{ON_PROCESS_END_FILE} or die $!;
  printf $FH "mode=%s pid=%s/%s ppid=%s/%s signal=%s\n", $mode, $pid, $$, $ppid, getppid,
    $ENV{DBIX_TEMP_DB_SIGNAL} // 'none';
  warn "# [$pid/$$] on-process-end.pl $mode wrote to $ENV{ON_PROCESS_END_FILE}\n" if $ENV{HARNESS_IS_VERBOSE};
  close $FH;
  kill USR2 => $ppid;
};

kill USR1 => $ppid;
undef $guard if $ENV{ON_PROCESS_EARLY};
sleep 1;
exit;
