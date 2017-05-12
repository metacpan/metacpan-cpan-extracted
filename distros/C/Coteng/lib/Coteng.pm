package Coteng;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.11";
our $DBI_CLASS = 'Coteng::DBI';

use Carp ();
use Module::Load ();
use Scope::Container;
use Scope::Container::DBI;
use SQL::NamedPlaceholder ();
use Class::Accessor::Lite::Lazy (
    rw => [qw(
        dbh
        current_dbname
        connect_info
    )],
    rw_lazy => [qw(
        sql_builder
    )],
    new => 1
);

use Coteng::DBI;
use Coteng::QueryBuilder;


sub db {
    my ($self, $dbname) = @_;
    $dbname or Carp::croak "dbname required";
    $self->current_dbname($dbname);
    $self->dbh($dbname);
    $self;
}

sub dbh {
    my ($self, $dbname) = @_;
    $dbname ||= $self->current_dbname or Carp::croak 'dbname or current_dbname required';

    my $db_info = $self->{connect_info}->{$dbname} || Carp::croak "'$dbname' doesn't exist";

    my ($dsn, $user, $passwd, $attr) = ('', '', '', {});
    if (ref($db_info) eq 'HASH') {
        $dsn    = $db_info->{dsn} || Carp::croak "dsn required";
        $user   = defined $db_info->{user}   ? $db_info->{user} : '';
        $passwd = defined $db_info->{passwd} ? $db_info->{passwd} : '';
        $attr   = $db_info->{attr};
    }
    elsif (ref($db_info) eq 'ARRAY') {
        ($dsn, $user, $passwd, $attr) = @$db_info;
    }
    else {
        Carp::croak 'connect_info->{$dbname} must be HASHref, or ARRAYref';
    }

    load_if_class_not_loaded($DBI_CLASS);

    unless (in_scope_container) {
        # define $CONTEXT forcelly to enable Scope::Container::DBI cache
        $self->{_dbh_container_dummy} = start_scope_container();
    }

    $attr->{RootClass} ||= $DBI_CLASS;
    my $dbh = Scope::Container::DBI->connect($dsn, $user, $passwd, $attr);
    $dbh;
}

sub _build_sql_builder {
    my ($self) = @_;
    return Coteng::QueryBuilder->new(driver => $self->dbh->{Driver}{Name});
}

sub single_by_sql {
    my ($self, $sql, $binds, $class) = @_;

    my $row = $self->dbh->select_row($sql, @$binds) || '';
    if ($class && $row) {
        load_if_class_not_loaded($class);
        $row = $class->new($row);
    }
    return $row;
}

sub single_named {
    my ($self, $sql, $bind_values, $class) = @_;
    ($sql, my $binds) = SQL::NamedPlaceholder::bind_named($sql, $bind_values);
    my $row = $self->single_by_sql($sql, $binds, $class);
    return $row;
}

sub search_by_sql {
    my ($self, $sql, $binds, $class) = @_;
    my $rows = $self->dbh->select_all($sql, @$binds) || [];
    if ($class && @$rows) {
        load_if_class_not_loaded($class);
        $rows = [ map { $class->new($_) } @$rows ];
    }
    return $rows;
}

sub search_named {
    my ($self, $sql, $bind_values, $class) = @_;
    ($sql, my $binds) = SQL::NamedPlaceholder::bind_named($sql, $bind_values);
    my $rows = $self->search_by_sql($sql, $binds, $class);
    return $rows;
}

sub execute {
    my $self = shift;
    $self->dbh->query($self->_expand_args(@_));
}

sub _validate_where {
    my ($self, $where) = @_;
    if (ref($where) ne "HASH" && ref($where) ne "ARRAY"
        && ref($where) ne "SQL::Maker::Condition" && ref($where) ne "SQL::QueryMaker") {
        Carp::croak "'where' required to be HASH or ARRAY or SQL::Maker::Condition or SQL::QueryMaker";
    }
}

sub single {
    my ($self, $table, $where, $opt) = @_;
    my $class = do {
        my $klass = pop;
        ref($klass) ? undef : $klass;
    };
    if (ref($opt) ne "HASH") {
        $opt = {};
    }

    $self->_validate_where($where);

    $opt->{limit} = 1;

    my ($sql, @binds) = $self->sql_builder->select(
        $table,
        $opt->{columns} || ['*'],
        $where,
        $opt
    );
    my $row = $self->single_by_sql($sql, \@binds, $class);
    return $row;
}

sub search {
    my ($self, $table, $where, $opt) = @_;
    my $class = do {
        my $klass = pop;
        ref($klass) ? undef : $klass;
    };
    if (ref($opt) ne "HASH") {
        $opt = {};
    }

    $self->_validate_where($where);

    my ($sql, @binds) = $self->sql_builder->select(
        $table,
        $opt->{'columns'} || ['*'],
        $where,
        $opt
    );
    my $rows = $self->search_by_sql($sql, \@binds, $class);
    return $rows;
}

sub fast_insert {
    my ($self, $table, $args, $prefix) = @_;

    my ($sql, @binds) = $self->sql_builder->insert(
        $table,
        $args,
        { prefix => $prefix },
    );
    $self->execute($sql, @binds);
    return $self->dbh->last_insert_id($table);
}

sub insert {
    my $self = shift;
    my ($table, $args, $opt) = @_;
    my $class = do {
        my $klass = pop;
        ref($klass) ? undef : $klass;
    };
    if (ref($opt) ne "HASH") {
        $opt = {};
    }

    if (ref($args) ne "HASH" && ref($args) ne "ARRAY") {
        Carp::croak "'args' required to be HASH or ARRAY";
    }

    $opt->{primary_key} ||= "id";

    my $id = $self->fast_insert($table, $args, $opt->{prefix});
    return $self->single($table, { $opt->{primary_key} => $id }, $class);
}

sub bulk_insert {
    my ($self, $table, $args) = @_;

    return undef unless scalar(@{$args || []});

    my $dbh = $self->dbh;
    my $can_multi_insert = $dbh->{Driver}{Name} eq 'mysql' ? 1 : 0;

    if ($can_multi_insert) {
        my ($sql, @binds) = $self->sql_builder->insert_multi($table, $args);
        $self->execute($sql, @binds);
    } else {
        # use transaction for better performance and atomicity.
        my $txn = $dbh->txn_scope();
        for my $arg (@$args) {
            $self->insert($table, $arg);
        }
        $txn->commit;
    }
}

sub update {
    my ($self, $table, $args, $where) = @_;

    my ($sql, @binds) = $self->sql_builder->update($table, $args, $where);
    $self->execute($sql, @binds);
}

sub delete {
    my ($self, $table, $where) = @_;

    my ($sql, @binds) = $self->sql_builder->delete($table, $where);
    $self->execute($sql, @binds);
}

sub count {
    my ($self, $table, $column, $where, $opt) = @_;

    if (ref $column eq 'HASH') {
        Carp::croak('Do not pass HashRef to second argument. Usage: $db->count($table[, $column[, $where[, $opt]]])');
    }

    $column ||= '*';

    my ($sql, @binds) = $self->sql_builder->select($table, [\"COUNT($column)"], $where, $opt);

    my ($cnt) = $self->dbh->select_one($sql, @binds);
    $cnt;
}

sub last_insert_id {
    my $self = shift;
    $self->dbh->last_insert_id;
}

sub txn_scope {
    my $self = shift;
    $self->dbh->txn_scope;
}

sub _expand_args (@) {
    my ($class, $query, @args) = @_;

    if (@args == 1 && ref $args[0] eq 'HASH') {
        ( $query, my $binds ) = SQL::NamedPlaceholder::bind_named($query, $args[0]);
        @args = @$binds;
    }

    return ($query, @args);
}

sub load_if_class_not_loaded {
    my $class = shift;
    if (! is_class_loaded($class)) {
        Module::Load::load $class;
    }
}

# stolen from Mouse::PurePerl
sub is_class_loaded {
    my $class = shift;

    return 0 if ref($class) || !defined($class) || !length($class);

    my $pack = \%::;

    foreach my $part (split('::', $class)) {
        $part .= '::';
        return 0 if !exists $pack->{$part};

        my $entry = \$pack->{$part};
        return 0 if ref($entry) ne 'GLOB';
        $pack = *{$entry}{HASH};
    }

    return 0 if !%{$pack};

    # check for $VERSION or @ISA
    return 1 if exists $pack->{VERSION}
             && defined *{$pack->{VERSION}}{SCALAR} && defined ${ $pack->{VERSION} };
    return 1 if exists $pack->{ISA}
             && defined *{$pack->{ISA}}{ARRAY} && @{ $pack->{ISA} } != 0;

    # check for any method
    foreach my $name( keys %{$pack} ) {
        my $entry = \$pack->{$name};
        return 1 if ref($entry) ne 'GLOB' || defined *{$entry}{CODE};
    }

    # fail
    return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

Coteng - Lightweight Teng

=head1 SYNOPSIS

    use Coteng;

    my $coteng = Coteng->new({
        connect_info => {
            db_master => {
                dsn     => 'dbi:mysql:dbname=server;host=dbmasterhost',
                user    => 'nobody',
                passwd  => 'nobody',
            },
            db_slave => {
                dsn     => 'dbi:mysql:dbname=server;host=dbslavehost',
                user    => 'nobody',
                passwd  => 'nobody',
            },
        },
    });

    # or

    my $coteng = Coteng->new({
        connect_info => {
            db_master => [
                'dbi:mysql:dbname=server;host=dbmasterhost', 'nobody', 'nobody', {
                    PrintError => 0,
                }
            ],
            db_slave => [
                'dbi:mysql:dbname=server;host=dbslavehost', 'nobody', 'nobody',
            ],
        },
    });

    # or

    use Coteng::DBI;

    my $dbh1 = Coteng::DBI->connect('dbi:mysql:dbname=server;host=dbmasterhost', 'nobody', 'npbody');
    my $dbh2 = Coteng::DBI->connect('dbi:mysql:dbname=server;host=dbslavehost', 'nobody', 'npbody');

    my $coteng = Coteng->new({
        dbh => {
            db_master   => $dbh1,
            db_slave    => $dbh2,
        },
    });


    my $inserted_host = $coteng->db('db_master')->insert(host => {
        name    => 'host001',
        ipv4    => '10.0.0.1',
        status  => 'standby',
    }, "Your::Model::Host");
    my $last_insert_id = $coteng->db('db_master')->fast_insert(host => {
        name    => 'host001',
        ipv4    => '10.0.0.1',
        status  => 'standby',
    });
    my $host = $coteng->db('db_slave')->single(host => {
        name => 'host001',
    }, "Your::Model::Host");
    my $hosts = $coteng->db('db_slave')->search(host => {
        name => 'host001',
    }, "Your::Model::Host");

    my $updated_row_count = $coteng->db('db_master')->update(host => {
        status => "working",
    }, {
        id => 10,
    });
    my $deleted_row_count = $coteng->db('db_master')->delete(host => {
        id => 10,
    });

    ## no blessed return value

    my $hosts = $coteng->db('db_slave')->single(host => {
        name => 'host001',
    });

    # Raw SQL interface

    my $host = $coteng->db('db_slave')->single_named(q[
        SELECT * FROM host where name = :name LIMIT 1
    ], { name => "host001" }, "Your::Model::Host");
    my $host = $coteng->db('db_slave')->single_by_sql(q[
        SELECT * FROM host where name = ? LIMIT 1
    ], [ "host001" ], "Your::Model::Host");

    my $hosts = $coteng->db('db_slave')->search_named(q[
        SELECT * FROM host where status = :status
    ], { status => "working" }, "Your::Model::Host");
    my $hosts = $coteng->db('db_slave')->search_named(q[
        SELECT * FROM host where status = ?
    ], [ "working" ], "Your::Model::Host");


    package Your::Model::Host;

    use Class::Accessor::Lite(
        rw => [qw(
            id
            name
            ipv4
            status
        )],
        new => 1,
    );


=head1 DESCRIPTION

Coteng is a lightweight L<Teng>, just as very simple DBI wrapper.
Teng is a simple and good designed ORMapper, but it has a little complicated functions such as the row class, iterator class, the schema definition class (L<Teng::Row>, L<Teng::Iterator> and L<Teng::Schema>).
Coteng doesn't have such functions and only has very similar Teng SQL interface.

Coteng itself has no transaction and last_insert_id implementation, but has thir interface thanks to L<DBIx::Sunny>.
(Coteng uses DBIx::Sunny as a base DB handler.)

=head1 METHODS

Coteng provides a number of methods to all your classes,

=over

=item $coteng = Coteng->new(\%args)

Creates a new Coteng instance.

    # connect new database connection.
    my $coteng = Coteng->new({
        connect_info => {
            dbname => {
                dsn     => $dsn,
                user    => $user,
                passwd  => $passwd,
                attr    => \%attr,
            },
        },
    });

Arguments can be:

=over

=item * C<connect_info>

Specifies the information required to connect to the database.
The argument should be a reference to a nested hash in the form:

    {
        dbname => {
            dsn     => $dsn,
            user    => $user,
            passwd  => $passwd,
            attr    => \%attr,
        },
    },

or a array referece in the form

    {
        dbname => [ $dsn, $user, $passwd, \%attr ],
    },

'dbname' is something you like to identify a database type such as 'db_master', 'db_slave', 'db_batch'.

=item C<$row = $coteng-E<gt>db($dbname)>

Set internal current db by $dbname registered in 'new' method.
Returns Coteng object ($self) to enable you to use method chain like below.

    my $row = $coteng->db('db_master')->insert();

=item C<$row = $coteng-E<gt>insert($table, \%row_data, [\%opt], [$class])>

Inserts a new record. Returns the inserted row object blessed $class.
If it's not specified $class, returns the hash reference.

    my $row = $coteng->db('db_master')->insert(host => {
        id   => 1,
        ipv4 => '192.168.0.0',
    }, { primary_key => 'host_id', prefix => 'SELECT DISTINCT' } );

'primary_key' default value is 'id'.
'prefix' default value is 'SELECT'.

If a primary key is available, it will be fetched after the insert -- so
an INSERT followed by SELECT is performed. If you do not want this, use
C<fast_insert>.

=item C<$last_insert_id = $teng-E<gt>fast_insert($table_name, \%row_data, [$prefix]);>

insert new record and get last_insert_id.

no creation row object.

=item C<$teng-E<gt>bulk_insert($table_name, \@rows_data)>

Accepts either an arrayref of hashrefs.
Each hashref should be a structure suitable for your table schema.
The second argument is an arrayref of hashrefs. All of the keys in these hashrefs must be exactly the same.

insert many record by bulk.

example:

    $coteng->db('db_master')->bulk_insert(host => [
        {
            id   => 1,
            name => 'host001',
        },
        {
            id   => 2,
            name => 'host002',
        },
        {
            id   => 3,
            name => 'host003',
        },
    ]);

=item C<$update_row_count = $coteng-E<gt>update($table_name, \%update_row_data, [\%update_condition])>

Calls UPDATE on C<$table_name>, with values specified in C<%update_ro_data>, and returns the number of rows updated. You may optionally specify C<%update_condition> to create a conditional update query.

    my $update_row_count = $coteng->db('db_master')->update(host =>
        {
            name => 'host001',
        },
        {
            id => 1
        }
    );
    # Executes UPDATE user SET name = 'host001' WHERE id = 1

=item C<$delete_row_count = $coteng-E<gt>delete($table, \%delete_condition)>

Deletes the specified record(s) from C<$table> and returns the number of rows deleted. You may optionally specify C<%delete_condition> to create a conditional delete query.

    my $rows_deleted = $coteng->db('db_master')->delete(host => {
        id => 1
    });
    # Executes DELETE FROM host WHERE id = 1

=item C<$row = $teng-E<gt>single($table_name, \%search_condition, \%search_attr, [$class])>

Returns (hash references or $class objects) or empty string ('') if sql result is empty

    my $row = $coteng->db('db_slave')->single(host => { id => 1 }, 'Your::Model::Host');

    my $row = $coteng->db('db_slave')->single(host => { id => 1 }, { columns => [qw(id name)] });

=item C<$rows = $coteng-E<gt>search($table_name, [\%search_condition, [\%search_attr]], [$class])>

Returns array reference of (hash references or $class objects) or empty array reference ([]) if sql result is empty.

    my $rows = $coteng->db('db_slave')->search(host => {id => 1}, {order_by => 'id'}, 'Your::Model::Host');

=item C<$row = $teng-E<gt>single_named($sql, [\%bind_values], [$class])>

Gets one record from execute named query
Returns empty string ( '' ) if sql result is empty.

    my $row = $coteng->db('db_slave')->single_named(q{SELECT id,name FROM host WHERE id = :id LIMIT 1}, {id => 1}, 'Your::Model::Host');

=item C<$row = $coteng-E<gt>single_by_sql($sql, [\@bind_values], $class)>

Gets one record from your SQL.
Returns empty string ('') if sql result is empty.

    my $row = $coteng->db('db_slave')->single_by_sql(q{SELECT id,name FROM user WHERE id = ? LIMIT 1}, [1], 'user');

=item C<$rows = $coteng-E<gt>search_named($sql, [\%bind_values], [$class])>

Execute named query
Returns empty array reference ([]) if sql result is empty.

    my $itr = $coteng->db('db_slave')->search_named(q[SELECT * FROM user WHERE id = :id], {id => 1}, 'Your::Model::Host');

If you give array reference to value, that is expanded to "(?,?,?,?)" in SQL.
It's useful in case use IN statement.

    # SELECT * FROM user WHERE id IN (?,?,?);
    # bind [1,2,3]
    my $rows = $coteng->db('db_slave')->search_named(q[SELECT * FROM user WHERE id IN :ids], {ids => [1, 2, 3]}, 'Your::Model::Host');

=item C<$rows = $coteng-E<gt>search_by_sql($sql, [\@bind_values], [$class])>

Execute your SQL.
Returns empty array reference ([]) if sql result is empty.

    my $rows = $coteng->db('db_slave')->search_by_sql(q{
        SELECT
            id, name
        FROM
            host
        WHERE
            id = ?
    }, [ 1 ]);

=item C<$count = $coteng-E<gt>count($table, [$table[, $column[, $where[, $opt]]])>

Execute count SQL.
Returns record counts.

    my $count = $coteng->count(host, '*', {
        status => 'working',
    });

=item C<$sth = $coteng-E<gt>execute($sql, [\@bind_values|@bind_values])>

execute query and get statement handler.

=item C<$id = $coteng-E<gt>last_insert_id()>

Returns last_insert_id.

=item C<$txn = $coteng-E<gt>txn_scope()>

Returns DBIx::TransactionManager::ScopeGuard object

    {
        my $txn = $coteng->db('db_master')->txn_scope();
        ...
        $txn->commit;
    }

=back

=head1 NOTE

=over

=item USING DBI CLASSES

default DBI CLASS is 'Coteng::DBI' (Coteng::DBI's parent is DBIx::Sunny). You can change DBI CLASS via $Coteng::DBI_CLASS.
'Your::DBI' class should be followed by DBIx::Sunny interface.

    local $Coteng::DBI_CLASS = 'Your::DBI';
    my $coteng = Coteng->new({ connect_info => ... });
    $coteng->dbh('db_master')->insert(...);

=back

=head1 SEE ALSO

=over

=item L<Teng>

=item L<DBIx::Sunny>

=item L<SQL::Maker>

=back

=head1 LICENSE

Copyright (C) y_uuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

y_uuki E<lt>yuki.tsubo@gmail.comE<gt>

=cut

