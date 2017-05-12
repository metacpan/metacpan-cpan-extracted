package DBIx::DataFactory;

use strict;
use warnings;
use Carp;

our $VERSION = '0.0.5';

use base qw(Class::Data::Inheritable Class::Accessor::Fast);
__PACKAGE__->mk_classdata('defined_types' => {});
__PACKAGE__->mk_accessors(qw(
    username password dsn dbh connect_attr
));

__PACKAGE__->add_type('DBIx::DataFactory::Type::Int');
__PACKAGE__->add_type('DBIx::DataFactory::Type::Num');
__PACKAGE__->add_type('DBIx::DataFactory::Type::Str');
__PACKAGE__->add_type('DBIx::DataFactory::Type::Set');

use Smart::Args;
use DBIx::Inspector;
use DBI;
use SQL::Maker;
use Sub::Install;
use Class::Load qw/load_class/;

use DBIx::DataFactory::Type;

sub create_factory_method {
    args my $self,
         my $method   => 'Str',
         my $table    => 'Str',
         my $dsn      => {isa => 'Str', optional => 1},
         my $username => {isa => 'Str', optional => 1},
         my $password => {isa => 'Str', optional => 1},
         my $dbh      => {isa => 'Object', optional => 1},
         my $connect_attr => {
             isa => 'HashRef', optional => 1,
         },
         my $auto_inserted_columns => {
             isa => 'HashRef', optional => 1, default => {},
         },
         my $install_package => {
             isa => 'Str', optional => 1, default => 'DBIx::DataFactory',
         },
         my $creator => {
             isa => 'CodeRef', optional => 1,
         };

    $username = $self->username unless $username;
    $password = $self->password unless $password;
    $dsn      = $self->dsn      unless $dsn;
    $dbh      = $self->dbh      unless $dbh;
    unless ((defined $username && defined $password && defined $dsn) || $dbh) {
        croak('either username, password and dsn for database, or dbh are required');
    }

    $connect_attr = $self->connect_attr || {} unless $connect_attr;
    $dbh ||= DBI->connect($dsn, $username, $password, $connect_attr);
    my $inspector = DBIx::Inspector->new(dbh => $dbh)
        or croak('cannot connect database');

    my ($inspector_table) = grep {$_->name eq $table} $inspector->tables;
    croak("cannot find table named $table") unless $inspector_table;

    my $table_columns = [map {$_->name} $inspector_table->columns];
    my $primary_keys  = [map {$_->name} $inspector_table->primary_key];

    my $builder  = SQL::Maker->new(driver => $dbh->{Driver}->{Name});

    Sub::Install::install_sub({
        code => sub {
            my ($class, %args) = @_;
            return $self->_factory_method(
                dbh            => $dbh,
                table          => $table,
                column_names   => $table_columns,
                builder        => $builder,
                primary_keys   => $primary_keys,
                auto_inserted_columns => $auto_inserted_columns,
                creator        => $creator,
                params         => \%args,
            );
        },
        into => $install_package,
        as   => $method,
    });

    return;
}

sub add_type {
    my ($class, $type) = @_;
    load_class($type);
    $class->defined_types->{$type->type_name} = $type;
}

sub _make_value_from_type_info {
    my ($class, $args) = @_;

    my $copy_arg = {};
    %$copy_arg = %$args;
    my $type_name = delete $copy_arg->{type};
    my $type_class = $class->defined_types->{$type_name}
        or croak("$type_name is not defined as type");

    return $type_class->make_value(%$copy_arg);
}

sub _factory_method {
    my ($self, %args) = @_;
    my $dbh            = $args{dbh};
    my $table          = $args{table};
    my $columns        = $args{column_names};
    my $params         = $args{params};
    my $builder        = $args{builder};
    my $pk             = $args{primary_keys};
    my $creator        = $args{creator};
    my $auto_inserted_columns = $args{auto_inserted_columns};

    my $values = {};
    for my $column (@$columns) {
        # insert specified value if specified
        my $specified = $params->{$column};
        if (defined $specified) {
            $values->{$column} = $specified;
            next;
        }

        # insert setting columns value
        my $default = $auto_inserted_columns->{$column};
        if (ref $default eq 'CODE') {
            $values->{$column} = $default->();
            next;
        }
        elsif (ref $default eq 'HASH') {
            my $value = DBIx::DataFactory->_make_value_from_type_info($default);
            $values->{$column} = $value;
            next;
        }
    }

    if ($creator) {
        return $creator->($values);
    }
    else {
        return $self->_insert(
            builder      => $builder,
            dbh          => $dbh,
            table        => $table,
            primary_keys => $pk,
            values       => $values,
        );
    }
}

sub _insert {
    my ($self, %args) = @_;
    my $builder = $args{builder};
    my $dbh     = $args{dbh};
    my $table   = $args{table};
    my $pk      = $args{primary_keys};
    my $values  = $args{values};

    # make sql for insert
    my ($sql, @binds) = $builder->insert($table, $values);

    # insert
    my $sth = $dbh->prepare($sql);
    $sth->execute(@binds);

    # set auto increment value
    if (scalar(@$pk) == 1 && not defined $values->{$pk->[0]}) {
        $values->{$pk->[0]} = $self->_last_insert_id(
            $dbh, $builder->{driver}, $table,
        );
    }

    # refetch data
    if (scalar(@$pk) == 1) {
        my ($sql, @binds) = $builder->select(
            $table,
            ['*'],
            { $pk->[0] => $values->{$pk->[0]} },
        );
        my $row_hash = $dbh->selectrow_hashref($sql, {}, @binds);
        return $row_hash if $row_hash;
    }

    return $values;
}

sub _last_insert_id {
    my ($self, $dbh, $driver, $table_name) = @_;

    if ( $driver eq 'mysql' ) {
        return $dbh->{mysql_insertid};
    } elsif ( $driver eq 'Pg' ) {
        return $dbh->last_insert_id( undef, undef, undef, undef,{ sequence => join( '_', $table_name, 'id', 'seq' ) } );
    } elsif ( $driver eq 'SQLite' ) {
        return $dbh->func('last_insert_rowid');
    } elsif ( $driver eq 'Oracle' ) {
        return;
    } else {
        Carp::croak "Don't know how to get last insert id for $driver";
    }
}

1;

__END__

=head1 NAME

DBIx::DataFactory - factory method maker for inserting test data

=head1 SYNOPSIS

    # schema
    CREATE TABLE test_factory (
      `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
      `int` int,
      `double` double,
      `string` varchar(255),
      `text` text DEFAULT NULL,

      PRIMARY KEY (id)
    ) DEFAULT CHARSET=binary;

    # in your t/*.t
    use DBIx::DataFactory;
    my $factory_maker = DBIx::DataFactory->new({
        username => 'nobody',
        password => 'nobody',
        dsn      => 'dbi:mysql:dbname=test_factory;host=localhost',
    });
    $factory_maker->create_factory_method(
        method   => 'create_factory_data',
        table    => 'test_factory',
        auto_inserted_columns => {
            int => {
                type => 'Int',
                size => 8,
            },
            double => sub { rand(100) },
            string => {
                type => 'Str',
                size => 10,
            },
        },
    );

    my $values = $factory_maker->create_factory_data(
        text => 'test text',
    );
    # or you can use DBIx::DataFactory->create_factory_data()
    my $int  = $values->{int};
    my $text = $values->{text};

    # will insert following data
    # +----+----------+------------------+------------+-----------+
    # | id | int      | double           | string     | text      |
    # +----+----------+------------------+------------+-----------+
    # |  1 | 60194256 | 3.03977754238112 | fHt4X0JDr9 | test text |
    # +----+----------+------------------+------------+-----------+

    $values = $factory_maker->create_factory_data(
        int    => 1,
        string => 'test',
    );

    # will insert following data
    # +----+------+-----------------+--------+------+
    # | id | int  | double          | string | text |
    # +----+------+-----------------+--------+------+
    # |  2 |    1 | 71.159467713824 | test   | NULL |
    # +----+------+-----------------+--------+------+

=head1 DESCRIPTION

This module helps you to make factory method for inserting data into database.  You can use this as fixture replacement.

=head1 METHODS

=head2 $class->new(%args)

Create a new DBIx::DataFactory object.

    # set up by username, password, and dsn
    my $factory_maker = DBIx::DataFactory->new({
        username => 'nobody',
        password => 'nobody',
        dsn      => 'dbi:mysql:dbname=test_factory;host=localhost',
    });

    # or set up by db handler
    my $dbh = DBI->connect(
        'dbi:mysql:dbname=test_factory;host=localhost',
        'nobody',
        'nobody',
    );
    my $factory_maker = DBIx::DataFactory->new({
        dbh => $dbh,
    });


Set up initial state by following parameters.

=over 4

=item * username

Database username.

=item * password

Database password

=item * dsn

Database dsn

=item * dbh

Database handler

=back

=head2 $self->create_factory_method(%args)

This installs the method, which helps inserting data into database, in the DBIx::DataFactory package by default.

    $factory_maker->create_factory_method(
        method   => 'create_factory_data',
        table    => 'test_factory',
        auto_inserted_columns => {
            int => {
                type => 'Int',
                size => 8,
            },
            string => {
                type => 'Str',
                size => 10,
            },
        },
    );

if this is the case, this make the method named 'create_factory_data'.  you can pass all columns value you defined in schema.

    my $values = $factory_maker->create_factory_data(
        int    => 5,
        string => 'string',
        text   => 'test text',
    );

    # this makes following data.
    +----+-----+--------+-----------+
    | id | int | string | text      |
    +----+-----+--------+-----------+
    |  1 |  5  | string | test text |
    +----+-----+--------+-----------+


    my $values = $factory_maker->create_factory_data;

    # this makes following data
    +----+----------+------------+------+
    | id | int      | string     | text |
    +----+----------+------------+------+
    |  2 | 59483011 | 9svzODgYyz | NULL |
    +----+----------+------------+------+

=head3 Parameters

=over 4

=item * method

Required parameter.  method name you want to create.

=item * table

Required parameter.  database table name.

=item * dsn

optional parameter.  database dsn.

=item * username

optional parameter.  database username.

=item * password

optional parameter.  database password.

=item * auto_inserted_columns

optional parameter.  if you have the table column which you want to insert data into automatically by default, you can specify this parameter.

for example, if you have columns named 'int', 'string', and 'text', you can specify following.

    $factory_maker->create_factory_method(
        method   => 'create_factory_data',
        table    => 'test_factory',
        auto_inserted_columns => {
            int => {
                type => 'Int',
                size => 8,
            },
            string => {
                type => 'Str',
                size => 10,
            },
            text => sub { String::Random->new->randregex('[a-z]{50}') }
        },
    );

if passed hashref, the method inserts data which is defined in specified type class automatically by default.  see also DBIx::DataFactory::Type.

if passed coderef, the method inserts value which the code returns.

Of cource, if you specify column value in installed method, the setting for the column is not used.

=item * install_package

optional parameter.  if you want to install the factory method to package except DBIx::DataFactory, please specify.

    $factory_maker->create_factory_method(
        method          => 'create_factory_data',
        table           => 'test_factory',
        install_package => 'test::DBIx::DataFactory',
    );

=item * creator

optional parameter.  if you want to use original method for creating data,  please specify coderef.

DBIx::DataFactory passes values for inserting to code.  the method created by create_factory_method returns values which passed coderef returns.

this is probably useful when you use ORM and set up trigger, or when you want to use blessed value as return value.

For example,

    $factory_maker->create_factory_method(
        method          => 'create_factory_data',
        table           => 'test_factory',
        creator => sub {
            my ($values) = @_;

            my $db = DBIx::Simple->connect(
                'dbi:mysql:test_factory', 'root', '',
            ); # your setting
            $db->abstract = SQL::Abstract->new;

            my $result = $db->insert('test_factory', $values);
            return $result;  # this is used for return value of create_factory_data
        },
    );

=back

=head2 add_type

you can add type class which define the rule of inserting data.  See also DBIx::DataFactory::Type.

    DBIx::DataFactory->add_type('DBIx::DataFactory::Type::Test');

=head1 REPOSITORY

https://github.com/shibayu36/p5-DBIx-DataFactory

=head1 AUTHOR

  C<< <shibayu36 {at} gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, Yuki Shibazaki C<< <shibayu36 {at} gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
