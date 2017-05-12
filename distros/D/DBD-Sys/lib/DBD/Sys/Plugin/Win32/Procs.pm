package DBD::Sys::Plugin::Win32::Procs;

use strict;
use warnings;
use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);

$VERSION  = "0.102";
@colNames = qw(pid ppid uid sess cmndline start fulltime virtsize fname state threads);

=pod

=head1 NAME

DBD::Sys::Plugin::Win32::Procs - provides a table containing running processes

=head1 SYNOPSIS

  $processes = $dbh->selectall_hashref("select * from procs", "pid");

=head1 ISA

  DBD::Sys::Plugin::Win32::Procs;
  ISA DBD::Sys::Table

=head1 DESCRIPTION

This module provides the table C<procs> for the MSWin32 compatible
environment (this might cover cygwin, too).

=head2 COLUMNS

=head3 pid

Process ID

=head3 ppid

Parent process ID

=head3 uid

UID of process

=head3 sess

Session ID

=head3 fulltime

User + system time

=head3 virtsize

Virtual memory size (bytes)

=head3 fname       

File name

=head3 start       

Start time (seconds since the epoch)

=head3 state       

State of process

=head3 cmndline

Full command line of process

=head3 threads      

Amount of threads used by this process

=cut

my ( $have_win32_process_info, $have_win32_process_commandline );

=head1 METHODS

=head2 get_col_names

Returns the column names of the table as named in L</Columns>

=cut

sub get_col_names() { @colNames }

=head2 get_primary_key

Returns 'pid' - which is the process identifier.

=cut

sub get_primary_key() { return 'pid'; }

=head2 collect_data

Retrieves the data from L<Win32::Process::Info> and put it into fetchable rows.

=cut

sub collect_data
{
    my $self = $_[0];
    my @data;

    unless ( defined($have_win32_process_info) )
    {
        ( $have_win32_process_info, $have_win32_process_commandline ) = ( 0, 0 );
        eval { require Win32::Process::Info;        $have_win32_process_info        = 1; };
        eval { require Win32::Process::CommandLine; $have_win32_process_commandline = 1; };

        Win32::Process::Info->import( 'NT', 'WMI' ) if ($have_win32_process_info);
        Win32::Process::CommandLine->import() if ($have_win32_process_commandline);
    }

    if ($have_win32_process_info)
    {
        for my $procInfo ( Win32::Process::Info->new()->GetProcInfo() )
        {
            ( my $uid = $procInfo->{OwnerSid} || 0 ) =~ s/.*-//;
            my $cli = "";
            Win32::Process::CommandLine::GetPidCommandLine( $procInfo->{ProcessId}, $cli )
              if ($have_win32_process_commandline);
            $cli ||= "";
            $cli =~ s{^\S+\\}{};
            $cli =~ s{\s+$}{};
            push(
                  @data,
                  [
                     $procInfo->{ProcessId},
                     $procInfo->{ParentProcessId} || 0,
                     $uid,
                     $procInfo->{SessionId} || 0,
                     $cli || $procInfo->{Name} || "<dead>",
                     $procInfo->{CreationDate},
                     int(
                          ( $procInfo->{KernelModeTime} || 0 ) +
                            ( $procInfo->{UserModeTime} || 0 ) + .499
                        ),
                     $procInfo->{VirtualSize} || $procInfo->{WorkingSetSize},
                     $procInfo->{ExecutablePath},
                     $procInfo->{_status} || $procInfo->{Status} || $procInfo->{ExecutionState},
                     $procInfo->{ThreadCount} || 1,
                  ]
                );
        }
    }

    return \@data;
}

=head1 PREREQUISITES

The module L<Win32::Process::Info> is required to provide data for the
table. In rare cases, it could be useful to have
L<Win32::Process::CommandLine> installed, too.

=head1 AUTHOR

    Jens Rehsack			Alexander Breibach
    CPAN ID: REHSACK
    rehsack@cpan.org			alexander.breibach@googlemail.com
    http://www.rehsack.de/

=head1 ACKNOWLEDGEMENTS

The primary hint how to provide this table for windows comes from
H.Merijn Brand.

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SUPPORT

Free support can be requested via regular CPAN bug-tracking system. There is
no guaranteed reaction time or solution time, but it's always tried to give
accept or reject a reported ticket within a week. It depends on business load.
That doesn't mean that ticket via rt aren't handles as soon as possible,
that means that soon depends on how much I have to do.

Business and commercial support should be acquired from the authors via
preferred freelancer agencies.

=cut

1;

