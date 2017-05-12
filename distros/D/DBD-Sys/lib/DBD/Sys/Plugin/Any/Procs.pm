package DBD::Sys::Plugin::Any::Procs;

use strict;
use warnings;
use vars qw($VERSION @colNames);

use base qw(DBD::Sys::Table);

=pod

=head1 NAME

DBD::Sys::Plugin::Any::Procs - provides a table containing running processes

=head1 SYNOPSIS

  $processes = $dbh->selectall_hashref("select * from procs", "pid");

=head1 ISA

  DBD::Sys::Plugin::Any::Procs
  ISA DBD::Sys::Table

=cut

$VERSION = "0.102";
@colNames = (
              qw(uid gid euid egid pid ppid pgrp sess priority ttynum flags),
              qw(fulltime ctime virtsize rss wchan fname start),
              qw(pctcpu state pctmem cmndline ttydev)
            );

my $haveProcProcessTable;

my %knownCols;

=head1 DESCRIPTION

This module provides the table C<procs> for any operating system (which is
supported by Proc::ProcessTable).

=head2 COLUMNS

=head3 uid

UID of process

=head3 gid

GID of process
 
=head3 euid

Effective UID of process

=head3 egid

Effective GID of process

=head3 pid

Process ID
 
=head3 ppid

Parent process ID
 
=head3 pgrp

Process group
 
=head3 sess

Session ID

=head3 cpuid

CPU ID of processor running on        # FIX ME!
 
=head3 priority

Priority of process
 
=head3 ttynum

TTY number of process
 
=head3 flags

Flags of process
 
=head3 fulltime

User + system time
 
=head3 ctime

Child user + system time
 
=head3 timensec

User + system nanoseconds part        # FIX ME!
 
=head3 ctimensec

Child user + system nanoseconds       # FIX ME!
 
=head3 qtime

Cumulative cpu time                   # FIX ME!
 
=head3 virtsize

Virtual memory size (bytes)
 
=head3 rss

Resident set size (bytes)
 
=head3 wchan

Address of current system call
 
=head3 fname

File name
 
=head3 start

Start time (seconds since the epoch)
 
=head3 pctcpu

Percent cpu used since process started
 
=head3 state

State of process
 
=head3 pctmem

Percent memory
 
=head3 cmndline

Full command line of process
 
=head3 ttydev

Path of process's tty
 
=head3 clname

Scheduling class name                 #FIX ME!

=head1 METHODS

=head2 get_col_names

Returns the column names of the table as named in L</Columns>

=cut

sub get_col_names() { @colNames }

=head2 get_primary_key

Returns 'pid' - which is the process identifier.

=cut

sub get_primary_key() { return 'pid'; }

my %colMap = (
               fulltime => 'time',
               virtsize => 'size',
             );

sub _init_knownCols
{
    my $table = $_[0];
    unless ( 0 == scalar(@$table) )
    {
        %knownCols = map {
            defined $colMap{$_} or $colMap{$_} = $_;
            my $fn = $colMap{$_};
            $@ = undef;
            eval { $table->[0]->$fn() };
            $_ => ( $@ ? 0 : 1 )
        } @colNames;
    }
}

=head2 collect_data

Retrieves the data from L<Proc::ProcessTable> and put it into fetchable rows.

=cut

sub collect_data()
{
    my @data;

    unless ( defined($haveProcProcessTable) )
    {
        $haveProcProcessTable = 0;
        eval {
            require Proc::ProcessTable;
            $haveProcProcessTable = 1;
        };
    }

    if ($haveProcProcessTable)
    {
        my $pt    = Proc::ProcessTable->new();
        my $table = $pt->table();

        _init_knownCols($table) if ( 0 == scalar( keys %knownCols ) );

        foreach my $proc ( @{$table} )
        {
            my @row;

            #@row = (@$pt{@colNames});      # calls an error, proc::processtable bugged, handle as seen below.
            @row = map { my $fn = $colMap{$_}; $knownCols{$_} ? $proc->$fn() : undef } @colNames;

            push( @data, \@row );
        }
    }

    return \@data;
}

=head1 PREREQUISITES

The module L<Proc::ProcessTable> is required to provide data for the table.

=head1 AUTHOR

    Jens Rehsack			Alexander Breibach
    CPAN ID: REHSACK
    rehsack@cpan.org			alexander.breibach@googlemail.com
    http://www.rehsack.de/

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
