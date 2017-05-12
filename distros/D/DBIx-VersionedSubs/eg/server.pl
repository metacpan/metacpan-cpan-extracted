#!/usr/bin/perl -w
use strict;
use DBIx::VersionedSubs::Server;

=head1 USAGE

This script implements the barebone
server program that runs the whole
application C<My::App> from the database.

Start this program after having created the
database via C<create.pl>.

=cut

my $s = DBIx::VersionedSubs::Server->new({
    port      => 80,
    dsn       => 'dbi:SQLite:dbname=db/seed.sqlite',
    namespace => 'My::App',
    dispatch  => 'handler',
})->run();
