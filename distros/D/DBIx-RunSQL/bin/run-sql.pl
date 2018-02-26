#!/usr/bin/perl -w
use strict;
use DBIx::RunSQL;

my $exitcode = DBIx::RunSQL->handle_command_line('myapp', \@ARGV);
exit $exitcode;

=head1 NAME

run-db.pl - Run SQL

=head1 SYNOPSIS

  run-sql.pl "select * from mytable where 1=0"

=head1 ABSTRACT

This sets up the database. The following
options are recognized:

=head1 OPTIONS

=over 4

=item C<--user> USERNAME

=item C<--password> PASSWORD

=item C<--dsn> DSN

The DBI DSN to use for connecting to
the database

=item C<--sql> SQLFILE

The alternative SQL file to use
instead of what is passed on the command line.

=item C<--quiet>

Output no headers for empty SELECT resultsets

=item C<--bool>

Set the exit code to 1 if at least one result row was found

=item C<--string>

Output the (single) column that the query returns as a string without
any headers

=item C<--format> formatter

Use a different formatter for table output. Supported formatters are

  tab - output results as tab delimited columns

  Text::Table - output results as ASCII table

=item C<--force>

Don't stop on errors

=item C<--help>

Show this message.

=back

=cut
