package DBIx::Conn::Pg;

our $DATE = '2018-07-08'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

sub import {
    require DBI;

    my $pkg  = shift;

    my $dsn;
    if (!defined($_[0]) || !length($_[0])) {
        $dsn = "DBI:Pg:";
    } elsif ($_[0] =~ /=/) {
        $dsn = "DBI:Pg:".shift;
    } else {
        $dsn = "DBI:Pg:dbname=".shift;
    }

    my $var = 'dbh';
    if (@_ && $_[0] =~ /\A\$(\w+)\z/) {
        $var = $1;
        shift;
    }

    my $user = ""; $user = shift if @_;
    my $pass = ""; $pass = shift if @_;

    my $dbh = DBI->connect($dsn, $user, $pass, {@_});

    my $caller = caller();
    {
        no strict 'refs';
        no warnings 'once';
        *{"$caller\::$var"} = \$dbh;
    }
}

1;
# ABSTRACT: Shortcut to connect to PostgreSQL database

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Conn::Pg - Shortcut to connect to PostgreSQL database

=head1 VERSION

This document describes version 0.001 of DBIx::Conn::Pg (from Perl distribution DBIx-Conn-Pg), released on 2018-07-08.

=head1 SYNOPSIS

In the command-line, instead of saying:

 % perl -MDBI -E'my $dbh = DBI->connect("dbi:Pg:", "", ""); $dbh->selectrow_array("query"); ...' ;# connect to database with the same name as current user
 % perl -MDBI -E'my $dbh = DBI->connect("dbi:Pg:dbname=mydb", "someuser", "somepass"); $dbh->selectrow_array("query"); ...'

you can just say:

 % perl -MDBI::Conn::Pg -E'$dbh->selectrow_array("query"); ...' ;# connect to database with the same name as current user
 % perl -MDBI::Conn::Pg=mydb,someuser,somedb -E'$dbh->selectrow_array("query"); ...'

To connect with some other L<DBD::Pg> parameters:

 % perl -MDBIx::Conn::Pg='dbname=mydb;host=192.168.1.10' -E'$dbh->selectrow_array("query"); ...'

To change the exported database variable name from the default '$dbh'

 % perl -MDBIx::Conn::Pg=mydb,'$handle' -E'$handle->selectrow_array("query"); ...'

To supply username and password:

 % perl -MDBIx::Conn::Pg=mydb,myuser,mysecret -E'$handle->selectrow_array("query"); ...'

To supply connection attributes:

 % perl -MDBIx::Conn::Pg=mydb,myuser,mysecret,AutoCommit,0 -E'$handle->selectrow_array("query"); ...'

=head1 DESCRIPTION

This module offers some saving in typing when connecting to a PostgreSQL
database using L<DBI>, and is particularly handy in one-liners. It automatically
C<connect()> and exports the database handle C<$dbh> for you.

You often only have to specify the database name in the import argument:

 -MDBIx::Conn::Pg=mydb

This will result in the following DSN:

 DBI:Pg:dbname=mydb

If you need to specify other parameters in the DSN, e.g. when the C<host> is not
C<localhost>, or the C<port> is not the default port, you can specify that in
the first import argument too (note the quoting because the shell will interpret
C<;> as command separator). When the first import argument contains C<=>, the
module knows that you want to specify DSN parameters:

 -MDBIx::Conn::Pg='dbname=mydb;host=192.168.1.10;port=23306'

this will result in the following DSN:

 'DBI:Pg:dbname=mydb;host=192.168.1.10;port=23306

If you want to use another variable name other than the default C<$dbh> for the
database handle, you can specify this in the second import argument (note the
quoting because otherwise the shell will substitute with shell variable):

 -MDBIx::Conn::Pg=mydb,'$handle'

If you want to supply username and password anyway, you can do that via the
third and fourth import arguments (or the second and third import arguments, as
long as the username does not begin with C<$>):

 -MDBIx::Conn::Pg=mydb,'$handle',myuser,mysecret
 -MDBIx::Conn::Pg=mydb,myuser,mysecret

But note that it's more recommended to specify password using the C<.pgpass>
mechanism.

Lastly, if you want to specify connection attributes, you can do that via the
fifth arguments and the rest (or the fourth and the rest, if you don't specify
custom handle name):

 -DBIx::Conn::Pg=mydb,,,AutoCommit,0

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DBIx-Conn-Pg>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DBIx-Conn-Pg>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Conn-Pg>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DBIx::Conn::MySQL>

L<DBIx::Conn::SQLite>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
