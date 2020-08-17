package DBIx::OpenTracing::Constants;
use strict;
use warnings;
use parent 'Exporter';
use Package::Constants;

use constant {
    DB_TAG_TYPE   => 'db.type',
    DB_TAG_SQL    => 'db.statement',
    DB_TAG_BIND   => 'db.statement.bind',
    DB_TAG_USER   => 'db.user',
    DB_TAG_DBNAME => 'db.instance',
    DB_TAG_ROWS   => 'db.rows',
};
use constant DB_TAGS_ALL => map { no strict 'refs'; &$_ } Package::Constants->list(__PACKAGE__);

our @EXPORT_OK   = Package::Constants->list(__PACKAGE__);
our %EXPORT_TAGS = (ALL => \@EXPORT_OK);

1;
__END__
=pod

=head1 NAME

DBIx::OpenTracing::Constants - name for use with DBIx::OpenTracing

=head1 SYNOPSIS

    use DBIx::OpenTracing::Constants ':ALL';
    
    DBIx::OpenTracing->hide_tags(DB_TAG_SQL);

=head1 EXPORTED CONSTANTS

This module exports the following constants
(C<:ALL> tag is supported to get them all):

=over 4

=item DB_TAG_TYPE

The database type (usually "sql").

=item DB_TAG_SQL

The SQL statement of the current query.

=item DB_TAG_BIND

Bind values of the current query.

=item DB_TAG_USER

Username used to connect to database.

=item DB_TAG_DBNAME

The database name.

=item DB_TAG_ROWS

Number of rows returned by the query.

=item DB_TAGS_ALL

A list with all possible tag names.

=back

=cut
