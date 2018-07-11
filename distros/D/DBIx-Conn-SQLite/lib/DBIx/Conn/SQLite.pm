package DBIx::Conn::SQLite;

our $DATE = '2018-07-08'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

sub import {
    require DBI;

    my $pkg  = shift;

    my $dsn;
    die "import(): Please supply at least a database name" unless @_;
    if ($_[0] =~ /=/) {
        $dsn = "DBI:SQLite:".shift;
    } else {
        $dsn = "DBI:SQLite:dbname=".shift;
    }

    my $var = 'dbh';
    if (@_ && $_[0] =~ /\A\$(\w+)\z/) {
        $var = $1;
        shift;
    }

    my $dbh = DBI->connect($dsn, "", "");

    my $caller = caller();
    {
        no strict 'refs';
        no warnings 'once';
        *{"$caller\::$var"} = \$dbh;
    }
}

1;
# ABSTRACT: Shortcut to connect to SQLite database

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Conn::SQLite - Shortcut to connect to SQLite database

=head1 VERSION

This document describes version 0.001 of DBIx::Conn::SQLite (from Perl distribution DBIx-Conn-SQLite), released on 2018-07-08.

=head1 SYNOPSIS

In the command-line, instead of saying:

 % perl -MDBI -E'my $dbh = DBI->connect("dbi:SQLite:dbname=mydb", "", ""); $dbh->selectrow_array("query"); ...'

or:

you can just say:

 % perl -MDBIx::Conn::SQLite=mydb -E'$dbh->selectrow_array("query"); ...'

To change the exported database variable name from the default '$dbh'

 % perl -MDBIx::Conn::SQLite=mydb,'$handle' -E'$handle->selectrow_array("query"); ...'

To supply connection attributes:

 % perl -MDBIx::Conn::SQLite=mydb,RaiseError,1 -E'$dbh->selectrow_array("query"); ...'

=head1 DESCRIPTION

This module offers some saving in typing when connecting to a SQLite database
using L<DBI>, and is particularly handy in one-liners. It automatically
C<connect()> and exports the database handle C<$dbh> for you.

You often only have to specify the database name in the import argument:

 -MDBIx::Conn::SQLite=mydb

This will result in the following DSN:

 DBI:SQLite:dbname=mydb

If you want to use another variable name other than the default C<$dbh> for the
database handle, you can specify this in the second import argument (note the
quoting because otherwise the shell will substitute with shell variable):

 -MDBIx::Conn::SQLite=mydb,'$handle'

Lastly, if you want to supply connection attributes, you can do so in the third
argument and the rest (or second and the rest, if you don't customize database
handle name):

 -MDBIx::Conn::SQLite=mydb,RaiseError,1

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DBIx-Conn-SQLite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DBIx-Conn-SQLite>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Conn-SQLite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DBIx::Conn::MySQL>

L<DBIx::Conn::Pg>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
