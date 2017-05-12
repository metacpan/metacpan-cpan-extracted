use strict;
package Benchmark::Harness::TraceHighRes;
use base qw(Benchmark::Harness::Trace);
use Benchmark::Harness;
use Benchmark::Harness::Constants;

use vars qw($VERSION); $VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

### ###########################################################################
sub Initialize {
  my $self = Benchmark::Harness::Trace::Initialize(@_);
  $self->{_startTime} = Time::HiRes::time();

# Things we get for the ProcessInfo element:
#
# W32 Linux   attr : meaning
#  X    X      'm' : virtual memory size (kilobytes)
#       X      'r' : resident set size (kilobytes)
#       X      'u' : user mode time (milliseconds)
#       X      's' : kernel mode time (milliseconds)
#       X      'x' : user + kernal time
#  ?    ?      't' : system time, since process started, from time()
#       X      'p' : percent cpu used since process started

## from i686-linux-64int-ld
#       'euid' => 509,
#       'priority' => 0,
#       'wchan' => 0,
#       'cmndline' => '/usr/local/bin/perl5.8.3 test.pl ',
#       'fname' => 'perl5.8.3',
#       'cmajflt' => 29001,
#       'state' => 'run',
#       'pid' => 24077,
#       'cwd' => '/goto/big/stats/lib/perl/Benchmark',
#       'cminflt' => 10703,
#       'exec' => '/usr/local/bin/perl5.8.3',
#       'uid' => 509,
#       'cstime' => 7000,
#       'minflt' => 7084,
#       'pctcpu' => '0.00',
#       'suid' => 509,
#       'utime' => 0,
#       'pgrp' => 24077,
#       'start' => '1116131498',
#       'gid' => 509,
#       'ttydev' => '/dev/pts/8',
#       'fgid' => 509,
#       'pctmem' => '0.00',
#       'time' => 0,
#       'sess' => 26032,
#       'egid' => 509,
#       'size' => 7208960,
#       'ttynum' => 34824,
#       'stime' => 0,
#       'ctime' => 8000,
#       'sgid' => 509,
#       'flags' => 1048576,
#       'cutime' => 1000,
#       'majflt' => 436,
#       'fuid' => 509,
#       'ppid' => 26032,
#       'rss' => 5177344

if ( $^O ne 'MSWin32' ) { # Assume Linux, for now . . .

  eval 'use Proc::ProcessTable';
  die $@ if $@;
  my $procProcessTbl = new Proc::ProcessTable('cache_ttys' => 1);

  *Benchmark::Harness::Handler::TraceHighRes::reportTraceInfo =
      sub {
          my $self = shift;

          my $processTable = $procProcessTbl->table;
          my $processIdx = $self->[Benchmark::Harness::Handler::HNDLR_PROCESSIDX];

          my $procInfo = $processTable->[$processIdx] if defined($processIdx);
          # Our process idx is probably the same each time through . . .
          unless ( ref($procInfo) && ($procInfo->{pid} == $$) ) {
            my $processIdx = 0;
            for ( @$processTable ) {
              if ( $_->{pid} == $$ ) {
                  $procInfo = $_;
                  last;
              } else {
                $processIdx += 1;
              }
            }
            $self->[HNDLR_PROCESSIDX] = $processIdx;
          }

          # a problem with Proc::ProcessTable needs to be fixed
          my $largeError = 2147483648;
          my $mMem = $procInfo->{size};
          $mMem = $largeError + ($largeError+$mMem) if ( $mMem < 0 );
          my $rMem = $procInfo->{rss};
          $rMem = $largeError + ($largeError+$rMem) if ( $rMem < 0 );

          # Note: we do not call direct-parent ::Trace, since we're duplicating all its attributes, anyway
          Benchmark::Harness::Handler::reportTraceInfo($self,
            {
               'm' => $mMem / 1024
              ,'p' => $procInfo->{pctcpu}
              ,'r' => $rMem / 1024
              ,'s' => $procInfo->{stime}
              ,'t' => (Time::HiRes::time() - $self->[HNDLR_HARNESS]->{_startTime})
              ,'u' => $procInfo->{utime}
              ,'x' => $procInfo->{time}/1000
            }
            ,@_
          );
      };
}
  return $self;
}


package Benchmark::Harness::Handler::TraceHighRes;
use base qw(Benchmark::Harness::Handler::Trace);
use Benchmark::Harness::Constants;
use Time::HiRes;

=pod

=head1 Benchmark::Harness::TraceHighRes

=head2 SYNOPSIS

(stay tuned . . . )

=head2 Impact


This produces a slightly larger XML report than the Trace harness, since HighRes times consume more digits than low-res ones.
This report will be about 20% larger than that of Trace.

=over 8

=item1 MSWin32

Approximately 0.8 millisecond per trace (mostly from *::Trace.pm).

=item1 Linux

=back

=cut

### ###########################################################################
sub reportTraceInfo {
  my $self = shift;

  Benchmark::Harness::Handler::Trace::reportTraceInfo($self,
              {
                't' => ( Time::HiRes::time() - $self->[HNDLR_HARNESS]->{_startTime} )
              }
              ,@_
          );
}

### ###########################################################################
# USAGE: Benchmark::TraceHighRes::OnSubEntry($harnessSubroutine, \@subrArguments )
sub OnSubEntry {
  my $self = shift;
  $self->reportTraceInfo();#(shift, caller(1));
  return @_; # return the input arguments unchanged.
}

### ###########################################################################
# USAGE: Benchmark::TraceHighRes::OnSubEntry($harnessSubroutine, \@subrReturn )
sub OnSubExit {
  my $self = shift;
  $self->reportTraceInfo();#(shift, caller(1));
  return @_; # return the input arguments unchanged.
}


### ###########################################################################

=head1 AUTHOR

Glenn Wood, <glennwood@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2004 Glenn Wood. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;