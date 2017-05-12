package DBIx::Table::TestDataGenerator::DBIxSchemaDumper;
use Moo;

use strict;
use warnings;

our $VERSION = "0.005";
$VERSION = eval $VERSION;

use Carp;

use DBI;
use DBIx::RunSQL;
use DBIx::Class::Schema::Loader qw/ make_schema_at /;

has dsn => (
    is       => 'ro',
    required => 1,
);

has user => (
    is       => 'ro',
    required => 1,
);

has password => (
    is       => 'ro',
    required => 1,
);

has table => (
    is       => 'ro',
    required => 1,
);

has on_the_fly_schema_sql => (
    is       => 'ro',
    required => 0,
);

sub dump_schema {
    my ($self) = @_;

    #make_schema_at disconnects the passed database handle, therefore we pass
    #a clone to it resp. the handle $dbh_for_schema_dump if defined
    my ( $dbh, $dbh_for_dump );
    if ( defined $self->on_the_fly_schema_sql ) {
        $dbh = DBIx::RunSQL->create(
            dsn => $self->dsn,
            sql => $self->on_the_fly_schema_sql,
        );
        $dbh_for_dump = DBIx::RunSQL->create(
            dsn => $self->dsn,
            sql => $self->on_the_fly_schema_sql,
        );
    }
    else {
        $dbh = DBI->connect( $self->dsn, $self->user, $self->password )
          or die $DBI::errstr;

        $dbh_for_dump = DBI->connect( $self->dsn, $self->user, $self->password )
          or die $DBI::errstr;
    }

    $dbh->{RaiseError}         = 1;
    $dbh->{ShowErrorStatement} = 1;
    $dbh->{AutoCommit}         = 0;

    $dbh_for_dump->{RaiseError}         = 1;
    $dbh_for_dump->{ShowErrorStatement} = 1;
    $dbh_for_dump->{AutoCommit}         = 0;

    my $attrs = {
        debug          => 0,
        dump_directory => '.',
        quiet          => 1,
    };

    make_schema_at( 'TDG::Schema', $attrs, [ sub { $dbh_for_dump }, {} ] );

    #in the current version, make_schema_at removes '.' from @INC, therefore:
    push @INC, '.';
    eval {
        require TDG::Schema;
        TDG::Schema->import();
        1;
    } or do {
        my $error = $@;
        croak $error;
    };

    my $h = TDG::Schema->connect( sub { $dbh } );
    $h->{RaiseError}         = 1;
    $h->{ShowErrorStatement} = 1;
    return [ $dbh, $h ];
}

1;    # End of DBIx::Table::TestDataGenerator::DBIxSchemaDumper

__END__

=pod

=head1 NAME

DBIx::Table::TestDataGenerator::DBIxSchemaDumper - Defines DBIx::Class schemata using DBIx::Class::Schema::Loader

=head1 DESCRIPTION

The current module uses DBIx::Class::Schema::Loader to create a DBIx::Class schema from the target database.

=head1 SUBROUTINES/METHODS

=head2 dsn

Accessor for the DBI data source name.

=head2 user

Accessor for the database user.

=head2 password

Accessor for the database user's password.

=head2 table

Read-only accessor for the name of the table in which the test data will be created.

=head2 dump_schema

Dumps the DBIx::Class schema for the current database to disk.

=head2 on_the_fly_schema_sql

If provided, is interpreted as the path to a file containing the definition for an in-memory SQLite database based on which the DBIx schema will be defined. This is used by the install process to run its tests against.

=head1 AUTHOR

Jose Diaz Seng, C<< <josediazseng at gmx.de> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Jose Diaz Seng.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For more details, see the full text of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose. 
