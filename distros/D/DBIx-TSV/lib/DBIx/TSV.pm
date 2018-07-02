package DBIx::TSV;

our $DATE = '2018-07-02'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;
use DBIx::TextTableAny;

sub import {
    my $class = shift;

    %DBIx::TextTableAny::opts = (
        @_,
        backend => 'Text::Table::TSV',
    );
}

package
    DBI::db;

sub selectrow_tsv          { local %DBIx::TextTableAny::opts = (backend => 'Text::Table::TSV', header_row => 1); &selectrow_texttable(@_) }
sub selectall_tsv          { local %DBIx::TextTableAny::opts = (backend => 'Text::Table::TSV', header_row => 1); &selectall_texttable(@_) }
sub selectrow_tsv_noheader { local %DBIx::TextTableAny::opts = (backend => 'Text::Table::TSV', header_row => 0); &selectrow_texttable(@_) }
sub selectall_tsv_noheader { local %DBIx::TextTableAny::opts = (backend => 'Text::Table::TSV', header_row => 0); &selectall_texttable(@_) }

package
    DBI::st;

sub fetchrow_tsv          { local %DBIx::TextTableAny::opts = (backend => 'Text::Table::TSV', header_row => 1); &fetchrow_texttable(@_) }
sub fetchall_tsv          { local %DBIx::TextTableAny::opts = (backend => 'Text::Table::TSV', header_row => 1); &fetchall_texttable(@_) }
sub fetchrow_tsv_noheader { local %DBIx::TextTableAny::opts = (backend => 'Text::Table::TSV', header_row => 0); &fetchrow_texttable(@_) }
sub fetchall_tsv_noheader { local %DBIx::TextTableAny::opts = (backend => 'Text::Table::TSV', header_row => 0); &fetchall_texttable(@_) }

1;
# ABSTRACT: Generate TSV from SQL query result

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::TSV - Generate TSV from SQL query result

=head1 VERSION

This document describes version 0.002 of DBIx::TSV (from Perl distribution DBIx-TSV), released on 2018-07-02.

=head1 SYNOPSIS

 use DBI;
 use DBIx::TSV;
 my $dbh = DBI->connect("dbi:mysql:database=mydb", "someuser", "somepass");

Generating a row of TSV (with header):

 print $dbh->selectrow_tsv("SELECT * FROM member");

Generating a row of TSV (without header):

Sample result:

 alice   pvt     123456

Generating all rows (with header):

 print $dbh->selectall_tsv("SELECT * FROM member");

Sample result:

 Name    Rank    Serial
 alice   pvt     123456
 bob     cpl     98765321
 carol   brig gen        8745

Generating all rows (without header):

 print $dbh->selectall_tsv_noheader("SELECT * FROM member");

Statement handle versions:

 print $sth->fetchrow_tsv;
 print $sth->fetchrow_tsv_noheader;
 print $sth->fetchall_tsv;
 print $sth->fetchall_tsv_noheader;

=head1 DESCRIPTION

This package is a thin glue between L<DBI> and L<DBIx::TextTableAny> (which in
turn is a thin glue to L<Text::Table::Any>). It adds the following methods to
database handle:

 selectrow_tsv
 selectall_tsv
 selectrow_tsv_noheader
 selectall_tsv_noheader

as well as the following methods to statement handle:

 fetchrow_tsv
 fetchall_tsv
 fetchrow_tsv_noheader
 fetchall_tsv_noheader

The methods send the result of query to Text::Table::Any (using the
L<Text::Table::TSV> backend) and return the rendered TSV data.

In essence, this is an easy, straightforward way produce TSV data from SQL
query.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DBIx-TSV>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DBIx-TSV>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-TSV>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DBIx::CSV>

L<DBIx::TextTableAny> which has a similar interface as this module and offers
multiple output formats.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
