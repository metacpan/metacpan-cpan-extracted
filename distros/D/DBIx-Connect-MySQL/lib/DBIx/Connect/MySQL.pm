package DBIx::Connect::MySQL;

our $DATE = '2017-08-16'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;
use Log::ger;

use DBI;

sub connect {
    my $pkg  = shift;
    my $dsn  = shift;
    my $user = shift;
    my $pass = shift;

  GET_USER_PASS_FROM_MY_CNF:
    {
        last if defined $user && defined $pass;
        if (-f (my $path = "$ENV{HOME}/.my.cnf")) {
            log_trace("Opening %s ...", $path);
            open my $fh, "<", $path or do {
                log_warn("Can't open %s: %s", $path, $!);
                last;
            };
            while (<$fh>) {
                if (!defined($user) && /^\s*user\s*=\s*(.+)/) {
                    log_trace("Setting DBI connection user from %s", $path);
                    $user = $1;
                    $user = $1 if $user =~ /\A"(.*)"\z/;
                }
                if (!defined($pass) && /^\s*password\s*=\s*(.+)/) {
                    log_trace("Setting DBI connection password from %s", $path);
                    $pass = $1;
                    $pass = $1 if $pass =~ /\A"(.*)"\z/;
                }

                last if defined $user && defined $pass;
            }
            close $fh;
        }
    }

    DBI->connect($dsn, $user, $pass, @_);
}

1;
# ABSTRACT: Connect to DBI (mysql), search user/password from .my.cnf

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Connect::MySQL - Connect to DBI (mysql), search user/password from .my.cnf

=head1 VERSION

This document describes version 0.002 of DBIx::Connect::MySQL (from Perl distribution DBIx-Connect-MySQL), released on 2017-08-16.

=head1 SYNOPSIS

Instead of:

 use DBI;
 my $dbh = DBI->connect("dbi:mysql:database=mydb", "someuser", "somepass");

you can now do:

 use DBIx::Connect::MySQL;
 my $dbh = DBIx::Connect::MySQL->connect("dbi:mysql:database=mydb", undef, undef);

and user/password will be searched in F<~/.my.cnf> if unset.

=head1 DESCRIPTION

This is a small wrapper for C<< DBI->connect >> because the client library does
not automatically search for user/password from F<.my.cnf> files like in
PostgresSQL.

=head1 METHODS

=head2 connect($dsn, $user, $pass, ...)

Will pass arguments to C<< DBI->connect >> after setting the default of C<$user>
and C<$pass> from F<~/.my.cnf> if possible.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DBIx-Connect-MySQL>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DBIx-Connect-MySQL>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Connect-MySQL>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
