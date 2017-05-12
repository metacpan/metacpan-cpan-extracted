use strict;
use Benchmark::Harness;
package Benchmark::Harness::Trace;
use base qw(Benchmark::Harness);
use Benchmark::Harness::Constants;

use vars qw($VERSION); $VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

### ###########################################################################
sub Initialize {
  my $self = Benchmark::Harness::Initialize(@_);

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

if ( $^O eq 'MSWin32' ) {

  $self->{XmlTempFilename} = 'C:/TEMP/benchmark_harness';
  eval 'use Win32::Process::Info';
  $self->{procInfo} = Win32::Process::Info->new(undef,'NT');

  *Benchmark::Harness::Handler::Trace::reportTraceInfo =
      sub {
            my $slf = shift;
            my $proc = ($slf->[HNDLR_HARNESS]->{procInfo}->GetProcInfo({no_user_info=>1},$$))[0];
            return Benchmark::Harness::Handler::reportTraceInfo($slf,
                {
                    'm' => $proc->{WorkingSetSize}/1024,
                    's' => $proc->{KernelModeTime} || '0',
                    't' => (time() - $slf->[HNDLR_HARNESS]->{_startTime}),
                    'u' => $proc->{UserModeTime},
                }
                ,@_
              );
          };
}
else { # Assume Linux, for now . . .

  $self->{XmlTempFilename} = '/tmp/benchmark_harness';

  *Benchmark::Harness::Handler::Trace::reportTraceInfo =
      sub {
          my $slf = shift;

          my $ps = `ps -l -p $$`;
          my ($pMem, $pTimeH, $pTimeM, $pTimeS) = ($ps =~ m{CMD(?:\s+\S+){9}\s+(\S+)(?:\s+\S+){2}\s+(\d+):(\d+):(\d+)}s);
          my $pTime = ( $pTimeH*60 + $pTimeM*60 ) + $pTimeS;

          return Benchmark::Harness::Handler::reportTraceInfo($slf,
            {
               'm' => $pMem
              ,'t' => (time() - $slf->[HNDLR_HARNESS]->{_startTime})
              ,'u' => $pTime
            }
            ,@_
          );
      };
}
  return $self;
}

package Benchmark::Harness::Handler::Trace;
use base qw(Benchmark::Harness::Handler);
use strict;


=pod

=head1 Benchmark::Harness::Trace

=head2 SYNOPSIS

A harness that records the time and sequence, and simple memory usage
of your program, at entries and exits of functions in the target program.

See Benchmark::Harness, "Parameters", for instruction on how to configure
a test harness, and use 'Trace' as your harness name.

=head2 REPORT

The report is an XML file with schema you can find in xsd/Trace.xsd,
or at http://schemas.benchmark-harness.org/Trace.xsd

For example:

  <Trace see-Benchmark::Harness-for-attributes-here>
    <T _i="0" _m="E" u="0.234375" m="0" s="0.109375" t="1"/>
    <T _i="2" _m="E" u="0.234375" m="0" s="0.109375" t="1"/>
    <T _i="2" _m="X" u="0.234375" m="0" s="0.109375" t="1"/>
    <T _i="0" _m="X" u="0.234375" m="0" s="0.109375" t="1"/>
  </Trace>

The @_i attribute is described in L<Benchmark::Harness|Benchmark::Harness>.
It identifies the name of the function being traced.

@_m will be 'E' or 'X', for entry or exit from the function.

@u is the user memory use at that moment, in megabytes.

@m is virtual memory size, in megabytes.

@s is kernal memory size, in megabytes.

@t is time since the Harness started, in seconds.

=head2 IMPACT

=over 8

=item1 MSWin32

Approximately 0.7 millisecond per trace.

=item1 Linux

=back

=head2 Available

=over 8

These process parameters are also available via this code, but are not transferred to the harness report.

=item1 MSWin32

  'Caption',
  'CommandLine',
  'CreationClassName',
  'CreationDate',
  'CSCreationClassName',
  'CSName',
  'Description',
  'ExecutablePath',
  'ExecutionState',
  'Handle',
  'HandleCount',
  'InstallDate',
  'KernelModeTime' => @s
  'MaximumWorkingSetSize',
  'MinimumWorkingSetSize',
  'Name',
  'OSCreationClassName',
  'OSName',
  'OtherOperationCount',
  'OtherTransferCount',
  'PageFaults',
  'PageFileUsage',
  'ParentProcessId',
  'PeakPageFileUsage',
  'PeakVirtualSize',
  'PeakWorkingSetSize',
  'Priority',
  'PrivatePageCount',
  'ProcessId',
  'QuotaNonPagedPoolUsage',
  'QuotaPagedPoolUsage',
  'QuotaPeakNonPagedPoolUsage',
  'QuotaPeakPagedPoolUsage',
  'ReadOperationCount',
  'ReadTransferCount',
  'SessionId',
  'Status',
  'TerminationDate',
  'ThreadCount',
  'UserModeTime' => @u
  'VirtualSize',
  'WindowsVersion',
  'WorkingSetSize' => @m
  'WriteOperationCount',
  'WriteTransferCount'

=item1 Linux

=back

=head2 SEE ALSO

L<Benchmark::Harness|Benchmark::Harness>

=cut

### ###########################################################################
sub reportValueInfo {
    return Benchmark::Harness::Handler::reportValueInfo(@_);
}

### ###########################################################################
sub OnSubEntry {
  my $self = shift;
  $self->reportTraceInfo();#(shift, caller(1));
  return @_; # return the input arguments unchanged.
}

### ###########################################################################
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