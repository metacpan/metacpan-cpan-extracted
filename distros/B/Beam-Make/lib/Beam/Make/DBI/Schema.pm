package Beam::Make::DBI::Schema;
our $VERSION = '0.003';
# ABSTRACT: A Beam::Make recipe to build database schemas

#pod =head1 SYNOPSIS
#pod
#pod     ### container.yml
#pod     # A Beam::Wire container to configure a database connection to use
#pod     sqlite:
#pod         $class: DBI
#pod         $method: connect
#pod         $args:
#pod             - dbi:SQLite:conversion.db
#pod
#pod     ### Beamfile
#pod     conversion.db:
#pod         $class: Beam::Wire::DBI::Schema
#pod         dbh: { $ref: 'container.yml:sqlite' }
#pod         schema:
#pod             - table: accounts
#pod               columns:
#pod                 - account_id: VARCHAR(255) NOT NULL PRIMARY KEY
#pod                 - address: TEXT NOT NULL
#pod
#pod =head1 DESCRIPTION
#pod
#pod This L<Beam::Make> recipe class builds a database schema.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Make>, L<Beam::Wire>, L<DBI>
#pod
#pod =cut

use v5.20;
use warnings;
use Moo;
use Time::Piece;
use List::Util qw( pairs );
use Digest::SHA qw( sha1_base64 );
use experimental qw( signatures postderef );

extends 'Beam::Make::Recipe';

#pod =attr dbh
#pod
#pod Required. The L<DBI> database handle to use. Can be a reference to a service
#pod in a L<Beam::Wire> container using C<< { $ref: "<container>:<service>" } >>.
#pod
#pod =cut

has dbh => ( is => 'ro', required => 1 );

#pod =attr schema
#pod
#pod A list of tables to create. Each table is a mapping with the following keys:
#pod
#pod =over
#pod
#pod =item table
#pod
#pod The name of the table to create.
#pod
#pod =item columns
#pod
#pod A list of key/value pairs of columns. The key is the column name, the value
#pod is the SQL to use for the column definition.
#pod
#pod =back
#pod
#pod =cut

has schema => ( is => 'ro', required => 1 );

sub make( $self, %vars ) {
    my $dbh = $self->dbh;

    # Now, prepare the changes to be made
    my @changes;
    for my $table_schema ( $self->schema->@* ) {
        my $table = $table_schema->{table};
        my @columns = $table_schema->{columns}->@*;
        my $table_info = $dbh->table_info( '', '%', qq{$table} )->fetchrow_arrayref;
        if ( !$table_info ) {
            push @changes, sprintf 'CREATE TABLE %s ( %s )', $dbh->quote_identifier( $table ),
                join ', ', map { join ' ', $dbh->quote_identifier( $_->key ), $_->value }
                    map { pairs %$_ } @columns;
        }
        else {
            my $column_info = $dbh->column_info( '', '%', $table, '%' )->fetchall_hashref( 'COLUMN_NAME' );
            # Compare columns and add if needed
            for my $pair ( map { pairs %$_ } @columns ) {
                my $column_name = $pair->key;
                my $column_type = $pair->value;
                if ( !$column_info->{ $column_name } ) {
                    push @changes, sprintf 'ALTER TABLE %s ADD COLUMN %s %s',
                        $table, $column_name, $column_type;
                }
            }
        }
    }

    # Now execute the changes
    for my $change ( @changes ) {
        $dbh->do( $change );
    }

    $self->cache->set( $self->name, $self->_cache_hash );
    return 0;
}

sub _cache_hash( $self ) {
    my $dbh = $self->dbh;
    my %tables;
    for my $table_info ( $dbh->table_info( '', '%', '%' )->fetchall_arrayref( {} )->@* ) {
        my $table_name = $table_info->{TABLE_NAME};
        for my $column_info ( $dbh->column_info( '', '%', $table_name, '%' )->fetchall_arrayref( {} )->@* ) {
            my $column_name = $column_info->{COLUMN_NAME};
            push $tables{ $table_name }->@*, $column_name;
        }
    }
    my $content = join ';',
        map { sprintf '%s=%s', $_, join ',', sort $tables{ $_ }->@* } sort keys %tables;
    return sha1_base64( $content );
}

sub last_modified( $self ) {
    return $self->cache->last_modified( $self->name, $self->_cache_hash );
}

1;

__END__

=pod

=head1 NAME

Beam::Make::DBI::Schema - A Beam::Make recipe to build database schemas

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    ### container.yml
    # A Beam::Wire container to configure a database connection to use
    sqlite:
        $class: DBI
        $method: connect
        $args:
            - dbi:SQLite:conversion.db

    ### Beamfile
    conversion.db:
        $class: Beam::Wire::DBI::Schema
        dbh: { $ref: 'container.yml:sqlite' }
        schema:
            - table: accounts
              columns:
                - account_id: VARCHAR(255) NOT NULL PRIMARY KEY
                - address: TEXT NOT NULL

=head1 DESCRIPTION

This L<Beam::Make> recipe class builds a database schema.

=head1 ATTRIBUTES

=head2 dbh

Required. The L<DBI> database handle to use. Can be a reference to a service
in a L<Beam::Wire> container using C<< { $ref: "<container>:<service>" } >>.

=head2 schema

A list of tables to create. Each table is a mapping with the following keys:

=over

=item table

The name of the table to create.

=item columns

A list of key/value pairs of columns. The key is the column name, the value
is the SQL to use for the column definition.

=back

=head1 SEE ALSO

L<Beam::Make>, L<Beam::Wire>, L<DBI>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
