package App::mimi::db;

use strict;
use warnings;

use Carp qw(croak);

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{dbh} = $params{dbh} or croak 'dbh required';

    $self->{columns} = [qw/no created status error/];

    return $self;
}

sub is_prepared {
    my $self = shift;

    local $SIG{__WARN__} = sub { };

    my $rv;
    eval { $rv = $self->{dbh}->do('SELECT 1 FROM mimi LIMIT 1') };

    return unless $rv;

    return 1;
}

sub prepare {
    my $self = shift;

    my $driver = $self->{dbh}->{Driver}->{Name};

    if ($driver eq 'SQLite') {
        $self->{dbh}->do(<<'EOF');
    CREATE TABLE mimi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created INTEGER NOT NULL,
        no INTEGER NOT NULL,
        status VARCHAR(32) NOT NULL,
        error VARCHAR(255)
    );
EOF
    } elsif ($driver eq 'Pg') {
        $self->{dbh}->do(<<'EOF');
    CREATE TABLE mimi (
        id serial PRIMARY KEY,
        created INTEGER NOT NULL,
        no INTEGER NOT NULL,
        status VARCHAR(32) NOT NULL,
        error VARCHAR(255)
    );
EOF
    }
}

sub fix_last_migration {
    my $self = shift;

    my $last_migration = $self->fetch_last_migration;
    return unless $last_migration;

    $self->{dbh}->do("UPDATE mimi SET status = 'success', error = '' WHERE id=$last_migration->{id}") or die $!;

    return $self;
}

sub create_migration {
    my $self = shift;
    my (%migration) = @_;

    $migration{created} ||= time;

    my $columns = join ',', keys %migration;
    my $values = join ',', map { "'$_'" } values %migration;

    $self->{dbh}->do("INSERT INTO mimi ($columns) VALUES ($values)") or die $!;

    return $self;
}

sub fetch_last_migration {
    my $self = shift;

    my $sth =
      $self->{dbh}->prepare(
        'SELECT id, no, created, status, error FROM mimi ORDER BY id DESC LIMIT 1');
    my $rv = $sth->execute or die $!;

    my $row = $sth->fetchall_arrayref->[0];
    return unless $row;

    my $migration = {};
    for (qw/id no created status error/) {
        $migration->{$_} = shift @$row;
    }

    return $migration;
}

1;
__END__
=pod

=head1 NAME

App::mimi::db - Database abstraction

=head1 SYNOPSIS

=head1 DESCRIPTION

Basic database abstractions. Just to keep SQL in one file.

=head1 METHODS

=head2 C<new>

Creates new object.

=head2 C<create_migration(%migration)>

Creates migration with provided options.

=head2 C<fetch_last_migration>

Fetches last migration.

=head2 C<fix_last_migration>

Sets last migration.

=head2 C<is_prepared>

Checks if journal is prepared.

=head2 C<prepare>

Creates journal database.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<viacheslav.t@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.

=cut
