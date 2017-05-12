package DBIPR;

use warnings;
use strict;
use Carp;
use Exporter 'import';
our @EXPORT = qw(raw_insert cursor_insert array_insert bulk_insert trunc session);
use DBI;
use DBD::Oracle qw(:ora_session_modes);

my $db;
croak "not able to login local default SID as scott/tiger!" unless 
  $db=DBI->connect(q(dbi:Oracle:), q(scott), q(tiger), {PrintError => 0});

=head1 NAME

DBIPR - DBI PRessure test for different methods of oracle insert

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Insert 1000 employees into emp table of scott user, in raw sql, cursor 
based insert, client side array based insert and server side array based
insert. Working as pressure testing application for DML tunning.
With DBI::Profile and oracle tkprof tools support, advanced measure is 
leave to experiment.

    use DBIPR;             # import all functions list below

    raw_insert; trunc;     # normal sql string concat method
    cursor_insert; trunc;  # cursor based version
    array_insert; trunc;   # perl array version
    bulk_insert; trunc;    # PL/SQL array version
    session;               # list all client sessions, for sql_trace & tkprof

Perl One-Liner command line works as:

    $ perl -MDBIPR -e "for (1..100) {trunc; sleep 3; cursor_insert; sleep 3;}"

=head1 FUNCTIONS

=head2 raw_insert

use raw sql 'insert into ... values ...' syntax and for loop

=cut

sub raw_insert {
  $db->do(qq(insert into emp(empno, ename) values ($_,'clerk$_'))) for 1..1000;
}

=head2 cursor_insert

use prepared statment with ? and bind_param inside for loop

=cut

sub cursor_insert {
  my $stmth=$db->prepare(qq(insert into emp(empno, ename) values (?,?)));
  $stmth->execute($_,"clerk$_") for 1..1000;
}

=head2 array_insert

use bind_param_array and execute_array to work in one shot

=cut

sub array_insert {
  my @empnos=(1..1000);
  my @enames=();
  my @rowstats=();
  $enames[$_-1]="clerk$_" for 1..1000;
  my $stmth=$db->prepare(qq(insert into emp(empno, ename) values (?,?)));
  $stmth->bind_param_array(1, \@empnos);
  $stmth->bind_param_array(2, \@enames);
  $stmth->execute_array({ArrayTupleStatus=>\@rowstats});
}

=head2 bulk_insert

use hash array (table of index) & forall insert to populate in pl/sql

=cut

sub bulk_insert {
  $db->do(q(
DECLARE
   TYPE NumTab IS TABLE OF NUMBER(4) INDEX BY BINARY_INTEGER;
   TYPE NameTab IS TABLE OF CHAR(10) INDEX BY BINARY_INTEGER;
   pnums  NumTab;
   pnames NameTab;
BEGIN
   FOR j IN 1..1000 LOOP  -- load index-by tables
      pnums(j) := j;
      pnames(j) := 'clerk' || TO_CHAR(j); 
   END LOOP;
   FORALL i IN 1..1000  -- use FORALL statement
      INSERT INTO emp (empno, ename) VALUES (pnums(i), pnames(i));
END;
));
}

=head2 trunc

use sql 'delete emp where deptno is null' to delete the test data

=cut

sub trunc {
  $db->do(qq(delete emp where deptno is null));
}

=head2 session

use v$process joined with v$session to report the sid, serial# of 
client programs. need to switch to sys account with account in dba group

=cut

sub session {
  my $sysdb=DBI->connect(q(dbi:Oracle:), q(), q(), 
    {ora_session_mode => ORA_SYSDBA});
  my $report=$sysdb->selectall_arrayref(q(
    select b.username, b.program, a.spid, b.sid, 
           b.serial# sno
      from v$process a join v$session b 
        on (a.addr=b.paddr and b.username is not null)
    ), {Slice=>{}});
  print qq(USER\tPROGRAM\tSID\tSERIAL\tSPID\n);
  print qq($_->{USERNAME}\t$_->{PROGRAM}\t$_->{SID}\t$_->{SNO}\t$_->{SPID}\n) 
    for (@$report);
  $sysdb->disconnect;
}

=head1 AUTHOR

Joe Jiang, C<< <lamp.purl at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dbipr at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIPR>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIPR

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIPR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIPR>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIPR>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIPR>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Joe Jiang, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of DBIPR
