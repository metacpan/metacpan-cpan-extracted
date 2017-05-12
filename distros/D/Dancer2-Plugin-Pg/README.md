# Name

[Dancer2::Plugin::Pg](https://metacpan.org/pod/Dancer2::Plugin::Pg) - PostgreSQL connection for Dancer2

# SYNOPSIS

    use Dancer2;
    use Dancer2::Plugin::Pg;
    
    my $sth = Pg->query('INSERT INTO table (bar, baz) VALUES (?, ?) RETURNING foo', 'value 1', 'value 2');
    print $sth->fetch->[0];

# CONFIGURATION

    plugins:
        Pg:
            host: 'localhost'
            port: '5432'
            base: 'database'
            username: 'postges'
            password: ''
            options:
                AutoCommit: 1
                AutoInactiveDestroy: 1
                PrintError: 0
                RaiseError: 1
                

Or connections:

    plugins:
        Pg:
            connections:
                default:
                    host: 'localhost'
                    port: '5432'
                    base: 'database1'
                    username: 'postges'
                    password: ''
                foo:
                    host: 'localhost'
                    port: '5432'
                    base: 'database2'
                    username: 'postges'
                    password: ''

default:

    my $pg = Pg;
    
foo:

    my $pg = Pg('foo');
    
# METHODS

### dbh

Return reference connection of DBI

    my $dbh = Pg->dbh;
    $dbh->do(
       q{
           CREATE TABLE table (
              id SERIAL,
              name VARCHAR(50) NOT NULL,
              PRIMARY KEY(id)
           );
       }
    );
    
### query

Method query is main, can be executed insert, update, delete and select.

    my $sth = Pg->query('SELECT * FROM table WHERE id = ?', 7);
    while (my @row = $sth->fetchrow_array) {
       print "@row\n";
    }
    
### selectOne

Method return only column.

    my $total = Pg->selectOne('SELECT COUNT(*) FROM table');
    print $total;
    
### selectRow

Method return row of data fetched.

    my $row = Pg->selectRow('SELECT bar, foo FROM table WHERE id = ?', 7);
    print $row->{bar}, $row->{foo};
    
### selectAll

Method return all rows of data fetched.

    my $all = Pg->selectAll('SELECT bar, foo FROM table');
    while(my $row = $all){
        print $row->{bar}, $row->{foo};
    }
    
### lastInsertID

Method return last insert id

    my $id = Pg->lastInsertID('table', 'column');
    
### column

Method used with methods: insert, update and delete.

    my $pg = Pg;
    $pg->table('foo');
    $pg->column('id', 1);
    $pg->column('name', 'bar');
    $pg->insert;
    
### insert

Method generate SQL and use method query to insert into database.

    my $pg = Pg;
    $pg->table('foo');
    $pg->column('name', 'bar');
    $pg->column('age', 7);
    $pg->returning('id, name'); # method RETURNING PostgreSQL
    my $result = $pg->insert;
    print $result->{id}, $result->{name};
    
### update

Method generate SQL and use method query to update into database.

    my $pg = Pg;
    $pg->table('foo');
    $pg->column('name', 'bar');
    $pg->returning('id, name'); # method RETURNING PostgreSQL
    my $result = $pg->update(id => 1);
    print $result->{id}, $result->{name};
    
### delete

Method generate SQL and use method query to delete into database.

    my $pg = Pg;
    $pg->table('foo');
    $pg->returning('*'); # method RETURNING PostgreSQL
    my $result = $pg->delete(OR => {age => {'>' => 5}, name => {'LIKE' => '%foo%'}}); # WHERE age > 5 OR name LIKE '%foo%'
    print $result->{foo};

# AUTHOR

Lucas Tiago de Moraes, <lucastiagodemoraes@gmail.com>

# LICENSE AND COPYRIGHT
This program is free software; you can redistribute it and/or modify it under the terms of either: the GNU General Public License as published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
