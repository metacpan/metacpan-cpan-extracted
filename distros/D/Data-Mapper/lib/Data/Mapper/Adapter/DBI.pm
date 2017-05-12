package Data::Mapper::Adapter::DBI;
use strict;
use warnings;
use parent qw(Data::Mapper::Adapter);

use Carp ();
use Data::Dumper ();

use SQL::Maker;
use DBIx::Inspector;

use Data::Mapper::Schema;

sub create {
    my ($self, $table, $values) = @_;
    my ($sql, @binds) = $self->sql->insert($table, $values);

    $self->execute($sql, @binds);

    my $schema       = $self->schemata->{$table};
    my $primary_keys = $schema->primary_keys;
    my $key          = $primary_keys->[0];

    if (scalar @$primary_keys == 1 && !defined $values->{$key}) {
        $values->{$key} = $self->last_insert_id($table);
    }

    $values;
}

sub find {
    my ($self, $table, $where, $options) = @_;
    my ($sql, @binds) = $self->select($table, $where, $options);
    my $sth = $self->execute($sql, @binds);

    $sth->fetchrow_hashref;
}

sub search {
    my ($self, $table, $where, $options) = @_;
    my ($sql, @binds) = $self->select($table, $where, $options);
    my $sth = $self->execute($sql, @binds);

    my @result;
    while (my $row = $sth->fetchrow_hashref) {
        push @result, $row;
    }

    \@result;
}

sub update {
    my ($self, $table, $set, $where) = @_;
    my ($sql, @binds) = $self->sql->update($table, $set, $where);

    $self->execute($sql, @binds);
}

sub delete {
    my ($self, $table, $where) = @_;
    my ($sql, @binds) = $self->sql->delete($table, $where);

    $self->execute($sql, @binds);
}

sub schemata {
    my $self = shift;

    if (!defined $self->{schemata}) {
        $self->{schemata} = {};

        for my $table ($self->inspector->tables) {
            $self->{schemata}{$table->name} = Data::Mapper::Schema->new({
                table        => $table->name,
                primary_keys => [ map { $_->name } $table->primary_key ],
                columns      => [ map { $_->name } $table->columns     ],
            });
        }
    }

    $self->{schemata};
}

### PRIVATE_METHODS ###

sub sql {
    my $self = shift;

    if (!defined $self->{sql}) {
        $self->{sql} = SQL::Maker->new(driver => $self->driver->{Driver}{Name});
    }

    $self->{sql};
}

sub inspector {
    my $self = shift;

    if (!defined $self->{inspector}) {
        $self->{inspector} = DBIx::Inspector->new(dbh => $self->driver);
    }

    $self->{inspector};
}

sub select {
    my ($self, $table, $where, $options) = @_;
    my $fields = ($options || {})->{fields} || ['*'];

    $self->sql->select($table, $fields, $where, $options);
}

sub execute {
    my ($self, $sql, @binds) = @_;
    my $sth;

    eval {
        $sth = $self->driver->prepare($sql);
        $sth->execute(@binds);
    };

    if ($@) {
        $self->handle_error($sql, \@binds, $@);
    }

    $sth;
}

sub handle_error {
    my ($self, $sql, $bind, $error) = @_;
    $sql =~ s/\n/\n          /gm;

    Carp::croak sprintf <<"TRACE", $error, $sql, Data::Dumper::Dumper($bind);
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@ Data::Mapper Exception @@@@@
Reason  : %s
SQL     : %s
BIND    : %s
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TRACE
}

sub last_insert_id {
    my ($self, $table) = @_;
    my $driver = $self->driver->{Driver}{Name};
    my $last_insert_id;

    if ($driver eq 'mysql') {
        $last_insert_id = $self->dbh->{mysql_insertid};
    }
    elsif ($driver eq 'Pg') {
        $last_insert_id = $self->driver->last_insert_id(
            undef, undef, undef, undef, {
                sequence => join('_', $table, 'id', 'seq')
            }
        );
    }
    elsif ($driver eq 'SQLite') {
        $last_insert_id = $self->driver->func('last_insert_rowid');
    }

    $last_insert_id;
}

sub check_table {
    my ($self, $table) = @_;
    $self->schemata->{$table} or Carp::croak("no such table: $table");
}

{
    no strict 'refs';
    no warnings 'redefine';

    for my $method (qw(create find search update delete)) {
        my $original = \&$method;

        *{__PACKAGE__."\::$method"} = sub {
            my ($self, $table) = @_;
            $self->check_table($table);
            $original->(@_);
        };
    }
}

!!1;
