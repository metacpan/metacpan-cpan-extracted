package DBIx::TextTableAny;

our $DATE = '2018-07-01'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;
use Text::Table::Any;

our %opts;

sub import {
    my $class = shift;

    %opts = @_;
}

package
    DBI::db;

sub selectrow_texttable {
    my $self = shift;
    my $statement = shift;

    my $sth = $self->prepare($statement);
    $sth->execute;

    Text::Table::Any::table(
        %DBIx::TextTableAny::opts,
        rows => [
            $sth->{NAME},
            $sth->fetchrow_arrayref,
        ],
    );
}

sub selectall_texttable {
    my $self = shift;
    my $statement = shift;

    my $sth = $self->prepare($statement);
    $sth->execute;

    Text::Table::Any::table(
        %DBIx::TextTableAny::opts,
        rows => [
            $sth->{NAME},
            @{ $sth->fetchall_arrayref },
        ],
    );
}

package
    DBI::st;

sub fetchrow_texttable {
    my $self = shift;

    Text::Table::Any::table(
        %DBIx::TextTableAny::opts,
        rows => [
            $self->{NAME},
            $self->fetchrow_arrayref,
        ],
    );
}

sub fetchall_texttable {
    my $self = shift;

    Text::Table::Any::table(
        %DBIx::TextTableAny::opts,
        rows => [
            $self->{NAME},
            @{ $self->fetchall_arrayref },
        ],
    );
}

1;
# ABSTRACT: Generate text table from SQL query result using Text::Table::Any

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::TextTableAny - Generate text table from SQL query result using Text::Table::Any

=head1 VERSION

This document describes version 0.002 of DBIx::TextTableAny (from Perl distribution DBIx-TextTableAny), released on 2018-07-01.

=head1 SYNOPSIS

 use DBI;
 use DBIx::TextTableAny;
 my $dbh = DBI->connect("dbi:mysql:database=mydb", "someuser", "somepass");

Selecting a row:

 print $dbh->selectrow_texttable("SELECT * FROM member");

Sample result (default backend is L<Text::Table::Tiny>):

 +-------+----------+----------+
 | Name  | Rank     | Serial   |
 +-------+----------+----------+
 | alice | pvt      | 123456   |
 +-------+----------+----------+

Selecting all rows:

 print $dbh->selectrow_texttable("SELECT * FROM member");

Sample result:

 +-------+----------+----------+
 | Name  | Rank     | Serial   |
 +-------+----------+----------+
 | alice | pvt      | 123456   |
 | bob   | cpl      | 98765321 |
 | carol | brig gen | 8745     |
 +-------+----------+----------+

Picking another backend (and setting other options):

 use DBIx::TextTableAny backend => 'Text::Table::CSV', header_row => 0;

 my $sth = $dbh->prepare("SELECT * FROM member");
 $sth->execute;

 print $sth->fetchall_texttable;

Sample result (note that we instructed the header row to be omitted):

 "alice","pvt","123456"
 "bob","cpl","98765321"
 "carol,"brig gen","8745"

If you want to change backend/options for subsequent tables, you can do this:

 DBIx::TextTableAny->import(backend => 'Text::Table::TSV', header_row => 0);
 print $dbh->selectrow_texttable("more query ...");

or:

 $DBIx::TextTableAny::opts{header_row} = 0; # you can just change one option
 print $dbh->selectrow_texttable("more query ...");

=head1 DESCRIPTION

This package is a thin glue between L<Text::Table::Any> and L<DBI>. It adds the
following methods to database handle:

 selectrow_texttable
 selectall_texttable

as well as the following methods to statement handle:

 fetchrow_texttable
 fetchall_texttable

The methods send the result of query to Text::Table::Any and return the rendered
table.

In essence, this is an easy, straightforward way produce text tables from SQL
query. You can generate CSV, ASCII table, or whatever format the
Text::Table::Tiny backend happens to support.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DBIx-TextTableAny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DBIx-TextTableAny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-TextTableAny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DBI::Format>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
