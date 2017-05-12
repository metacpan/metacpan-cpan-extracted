package Dancer2::Plugin::Pg;

use Dancer2::Plugin;
use Dancer2::Plugin::Pg::Core;

our $VERSION = '0.07';

register Pg => sub {
    my $dsl = shift;
    my $connection = shift;
    my $conf;
    if($connection) {
        $conf = plugin_setting()->{connections}->{$connection};
    }else{
        if (plugin_setting()->{connections}->{default}) {
            $conf = plugin_setting()->{connections}->{default};
        }else{
            $conf = plugin_setting();
        }
    }
    
    return Dancer2::Plugin::Pg::Core->new($conf);
};

register_plugin;

1;

__END__

=encoding utf8
 
=head1 NAME

Dancer2::Plugin::Pg - PostgreSQL connection for Dancer2

=head1 SYNOPSIS

    use Dancer2;
    use Dancer2::Plugin::Pg;
    
    my $sth = Pg->query('INSERT INTO table (bar, baz) VALUES (?, ?) RETURNING foo', 'value 1', 'value 2');
    print $sth->fetch->[0];
    
=head1 CONFIGURATION

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



=head1 METHODS

=head3 dbh

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

=head3 query

Method query is main, can be executed insert, update, delete and select.

    my $sth = Pg->query('SELECT * FROM table WHERE id = ?', 7);
    while (my @row = $sth->fetchrow_array) {
       print "@row\n";
    }

=head3 selectOne

Method return only column.

    my $total = Pg->selectOne('SELECT COUNT(*) FROM table');
    print $total;

=head3 selectRow

Method return row of data fetched.

    my $row = Pg->selectRow('SELECT bar, foo FROM table WHERE id = ?', 7);
    print $row->{bar}, $row->{foo};
 
=head3 selectAll

Method return all rows of data fetched.

    my $all = Pg->selectAll('SELECT bar, foo FROM table');
    while(my $row = $all){
        print $row->{bar}, $row->{foo};
    }

=head3 lastInsertID

Method return last insert id

    my $id = Pg->lastInsertID('table', 'column');

=head3 column

Method used with methods: insert, update and delete.

    my $pg = Pg;
    $pg->table('foo');
    $pg->column('id', 1);
    $pg->column('name', 'bar');
    $pg->insert;

=head3 insert

Method generate SQL and use method B<query> to insert into database.

    my $pg = Pg;
    $pg->table('foo');
    $pg->column('name', 'bar');
    $pg->column('age', 7);
    $pg->returning('id, name'); # method RETURNING PostgreSQL
    my $result = $pg->insert;
    print $result->{id}, $result->{name};

=head3 update

Method generate SQL and use method B<query> to update into database.

    my $pg = Pg;
    $pg->table('foo');
    $pg->column('name', 'bar');
    $pg->returning('id, name'); # method RETURNING PostgreSQL
    my $result = $pg->update(id => 1);
    print $result->{id}, $result->{name};

=head3 delete

Method generate SQL and use method B<query> to delete into database.

    my $pg = Pg;
    $pg->table('foo');
    $pg->returning('*'); # method RETURNING PostgreSQL
    my $result = $pg->delete(OR => {age => {'>' => 5}, name => {'LIKE' => '%foo%'}}); # WHERE age > 5 OR name LIKE '%foo%'
    print $result->{foo};

=head1 AUTHOR
 
Lucas Tiago de Moraes, C<< <lucastiagodemoraes@gmail.com> >>

=head1 LICENSE AND COPYRIGHT
 
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
 
See http://dev.perl.org/licenses/ for more information.