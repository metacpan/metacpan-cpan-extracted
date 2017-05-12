package DBIx::NoSQLite;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: An embedded, NoSQL SQLite database with SQL indexing
$DBIx::NoSQLite::VERSION = '0.0021';
use strict;
use warnings;

use DBIx::NoSQL::Store;
use DBD::SQLite;

sub new {
    my $class = shift;
    return DBIx::NoSQL::Store->new( @_ );
}

sub connect {
    my $class = shift;
    return DBIx::NoSQL::Store->connect( @_ );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::NoSQLite - An embedded, NoSQL SQLite database with SQL indexing

=head1 VERSION

version 0.0021

=head1 SYNOPSIS

    use DBIx::NoSQLite;

    my $store = DBIx::NoSQLite->connect( 'store.sqlite' );

    $store->set( ... );

    $store->get( ... );

    $store->exists( ... );

    $store->delete( ... );

    $store->search( ... );

    ...

Refer to L<DBIx::NoSQL>

=head1 DESCRIPTION

DBIx::NoSQLite a key/value store using SQLite as the backend

Refer to L<DBIx::NoSQL> for documentation and usage

=head1 AUTHORS

=over 4

=item *

Robert Krimen <robertkrimen@gmail.com>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
