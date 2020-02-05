package DBIx::ThinSQL::Drop;
use strict;
use warnings;
use Path::Tiny;
use DBIx::ThinSQL::Deploy;

our $VERSION = '0.0.49';

sub _doit {
    my $self   = shift;
    my $type   = shift;
    my $driver = $self->{Driver}->{Name};
    my $file   = $self->share_dir->child( 'Drop', $driver, $type . '.sql' );

    return $self->run_file($file) if -f $file;
    Carp::croak "Drop $type for driver $driver is unsupported.";
}

sub DBIx::ThinSQL::db::drop_indexes {
    my $self = shift;
    return _doit( $self, 'indexes' );
}

sub DBIx::ThinSQL::db::drop_functions {
    my $self = shift;
    return _doit( $self, 'functions' );
}

sub DBIx::ThinSQL::db::drop_languages {
    my $self = shift;
    return _doit( $self, 'languages' );
}

sub DBIx::ThinSQL::db::drop_sequences {
    my $self = shift;
    return _doit( $self, 'sequences' );
}

sub DBIx::ThinSQL::db::drop_tables {
    my $self = shift;
    return _doit( $self, 'tables' );
}

sub DBIx::ThinSQL::db::drop_triggers {
    my $self = shift;
    return _doit( $self, 'triggers' );
}

sub DBIx::ThinSQL::db::drop_views {
    my $self = shift;
    return _doit( $self, 'views' );
}

sub DBIx::ThinSQL::db::drop_everything {
    my $self = shift;
    return _doit( $self, 'indexes' ) +
      _doit( $self, 'functions' ) +
      _doit( $self, 'languages' ) +
      _doit( $self, 'sequences' ) +
      _doit( $self, 'tables' ) +
      _doit( $self, 'triggers' ) +
      _doit( $self, 'views' );
}

1;

__END__

=head1 NAME

DBIx::ThinSQL::Drop - Clean database support for DBIx::ThinSQL

=head1 VERSION

0.0.49 (2020-02-04) development release.

=head1 SYNOPSIS

    use DBIx::ThinSQL;
    use DBIx::ThinSQL::Drop;

    my $db = DBIx::ThinSQL->connect('dbi:SQLite:dbname=test');

    # After this you can run your tests with a freshly
    # cleaned database.
    $db->drop_everything();


=head1 DESCRIPTION

B<DBIx::ThinSQL::Drop> adds support to L<DBIx::ThinSQL> for cleaning
out your database. This is mostly useful when running tests with
something like L<Test::Database> where you don't know who was doing
what with your test database.

This module currently only works with SQLite and PostgreSQL databases.

B<*WARNING*> All of the following methods EAT YOUR DATA! B<*WARNING*>

=head1 METHODS

=over 4

=item drop_functions

Drops all functions from the database.

=item drop_indexes

Drops all indexes from the database.


=item drop_languages

Drops all languages from the database.


=item drop_sequences

Drops all sequences from the database.


=item drop_table

Drops all tables from the database.


=item drop_triggers

Drops all triggers from the database.


=item drop_views

Drops all views from the database.


=item drop_everything

Drops all tables, sequences, triggers and functions from the database.

=back

=head1 SEE ALSO

L<DBIx::ThinSQL>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2020 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

