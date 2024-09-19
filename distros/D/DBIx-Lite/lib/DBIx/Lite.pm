package DBIx::Lite;
$DBIx::Lite::VERSION = '0.35';
# ABSTRACT: Chained and minimal ORM
use strict;
use warnings;

use Carp qw(croak);
use DBIx::Connector;
use DBIx::Lite::ResultSet;
use DBIx::Lite::Row;
use DBIx::Lite::Schema;
use SQL::Abstract::More;

$Carp::Internal{$_}++ for __PACKAGE__, qw(DBIx::Connector);

sub new {
    my $class = shift;
    my (%params) = @_;
    
    my $self = {
        schema      => delete $params{schema} || DBIx::Lite::Schema->new,
        abstract    => SQL::Abstract::More->new(
            %{ delete $params{abstract} || {} },
        ),
        connector   => delete $params{connector},
        dbh         => delete $params{dbh},
    };

    if (!$params{connector} && $params{driver_name}) {
        $self->{connector} = DBIx::Connector->new('DBI:' . delete $params{driver_name});
    }
    
    !%params
        or croak "Unknown options: " . join(', ', keys %params);
    
    ref $self->{schema} eq 'DBIx::Lite::Schema'
        or croak "schema must be a DBIx::Lite::Schema object";
    
    bless $self, $class;
    $self;
}

sub connect {
    my $class = shift;
    my $self = ref $class ? $class : $class->new;
    
    $self->{connector} = DBIx::Connector->new(@_);
    $self->{dbh} = undef;
    $self->dbh(1) or return undef;
    $self->dbh->{HandleError} = sub { croak $_[0] };
    
    $self;
}

sub schema {
    my $self = shift;
    if (ref $_[0] eq 'DBIx::Lite::Schema') {
        $self->{schema} = $_[0];
        return $self;
    }
    $self->{schema};
}

sub table {
    my $self = shift;
    my $table_name = shift or croak "Table name missing";
    
    my $table = $self->schema->table($table_name);
    my $package = $table->resultset_class || 'DBIx::Lite::ResultSet';
    $package->_new(
        dbix_lite   => $self,
        table       => $table,
    );
}

sub dbh {
    my $self = shift;
    my ($dont_die) = @_;
    
    my $dbh = $self->{dbh} ? $self->{dbh}
        : $self->{connector} ? $self->{connector}->dbh
        : undef;
    return $dbh ? $dbh
        : $dont_die ? undef
        : croak "No database handle or DBIx::Connector object provided";
}

sub dbh_do {
    my $self = shift;
    my $code = shift;
    
    if ($self->{connector}) {
        return $self->{connector}->run($code);
    } else {
        $_ = $self->dbh;
        return $code->();
    }
}

sub txn {
    my $self = shift;
    my $code = shift;
    
    if ($self->{connector}) {
        return $self->{connector}->txn($code);
    } else {
        $self->dbh->begin_work;
        eval { $code->() };
        if (my $err = $@) {
            eval { $self->dbh->rollback };
            croak $err;
        }
        $self->dbh->commit;
    }
}

sub driver_name {
    my $self = shift;
    
    return $self->{connector} ? $self->{connector}->driver_name : $self->dbh->{Driver}->{Name};
}

sub _autopk {
    my $self = shift;
    my $table_name = shift;
    
    my $driver_name = $self->driver_name;
    
    if ($driver_name eq 'mysql') {
        return $self->dbh_do(sub { +($_->selectrow_array('SELECT LAST_INSERT_ID()'))[0] });
    } elsif ($driver_name eq 'SQLite') {
        return $self->dbh_do(sub { +($_->selectrow_array('SELECT LAST_INSERT_ROWID()'))[0] });
    } elsif ($driver_name eq 'Pg') {
        return $self->dbh_do(sub { $_->last_insert_id( undef, undef, $table_name, undef ) });
    } else {
        croak "Autoincrementing ID is not supported on $driver_name";
    }
}

sub _quote {
    my $self = shift;
    
    return $self->{abstract}->_quote(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Lite - Chained and minimal ORM

=head1 VERSION

version 0.35

=head1 SYNOPSIS

    use DBIx::Lite;
    
    my $dbix = DBIx::Lite->new(driver_name => 'Pg');  # disconnected mode
    my $dbix = DBIx::Lite->new(dbh => $dbh);
    my $dbix = DBIx::Lite->connect("dbi:Pg:dbname=$db", $user, $passwd, {pg_enable_utf8 => 1});
    
    # build queries using chained methods -- no schema definition required
    my $authors_rs = $dbix->table('authors');
    my $authors_rs = $dbix->table('authors')->search({ country => 'IT' });
    my $books_rs = $dbix
        ->table('books')
        ->select('id', 'title', 'year')
        ->left_join('authors', { author_id => 'id' })
        ->select_also(['authors.name' => 'author_name'])
        ->order_by('year');
    
    # retrieve rows and columns -- still no schema definition required
    my @authors = $authors_rs->all;
    my $author = $authors_rs->search({ id => 1 })->single;
    while (my $book = $books_rs->next) {
        printf "%s (%s)\n", $book->title, $book->author_name;  # automatic accessor methods
    }
    my @author_names = $authors_rs->get_column('name');
    my $book_count = $books_rs->count;
    
    # manipulate rows
    my $book = $dbix->table('books')->insert({ name => 'Camel Tales', year => 2012 });
    $books_rs->search({ year => { '<' => 1920 } })->update({ very_old => 1 });
    $authors_rs->search({ age => { '>' => 99 } })->delete;
    
    # define a primary key and get more features
    $dbix->schema->table('authors')->autopk('id');
    my $author = $dbix_lite->table('authors')->find(2);
    $author->update({ age => 40 });
    $author->delete;
    
    # define relationships
    $dbix->schema->one_to_many('authors.id' => 'books.author_id', 'author');
    my $author = $books->author;
    my $books_rs = $author->books->search({ year => 2012 });
    my $book = $author->insert_related('books', { title => "A Camel's Life" });
    
    # define custom object classes
    $dbix->schema
        ->table('subjects')
        ->class('My::Subject')
        ->resultset_class('My::Subject::ResultSet');

=head1 ABSTRACT

Many ORMs and DBI abstraction layers are available on CPAN, one of the most notables
being L<DBIx::Class> which provides the most powerful features to handle database
contents using OOP.

DBIx::Lite was written with some goals in mind, that no other available module provides.
Such goals/key features are:

=over 4

=item no need to define your database schema (most features work without one and some advanced features only require some bits, and still not the full table definitions)

=item no need to connect to database: the module can just generate SQL for you

=item chained methods with lazy SQL generation

=item joins/relationships

=item optional custom classes for results and resultsets with custom methods

=item L<SQL::Abstract> syntax

=item paging features (with L<Data::Page>)

=back

=head1 METHODS

Instantiating a DBIx::Lite object isn't more difficult than just writing:

    my $dbix = DBIx::Lite->new(driver_name => 'Pg');

Driver name is the name of the DBI module you expect to use. We need to specify it as the
generated SQL will depend on the driver.
This constructor will give you an unconnected object, that you can use to generate SQL commands using
the L<select_sql()>, L<insert_sql()>, L<update_sql()> and L<delete_sql()> methods without 
executing it.

If you want to connect to a database you can pass a pre-connected database handle with the 
C<dbh> argument or you can supply your connection options to the C<connect()> method. All
arguments passed to C<connect()> will be just passed to L<DBIx::Connector> which will be
used to manage your connection under the hood.

    my $dbix = DBIx::Lite->new(dbh => $dbh);
    my $dbix = DBIx::Lite->connect("dbi:Pg:dbname=$db", $user, $passwd, {pg_enable_utf8 => 1});

Note that C<connect()> can be called as an object method too, if you want to connect an
unconnected DBIx::Lite object at a later stage:

    my $dbix = DBIx::Lite->new;
    $dbix->connect("dbi:Pg:dbname=$db", $user, $passwd);

=head2 new

This class method may accept the following optional arguments:

=over 4

=item I<dbh>

This argument allows you to supply a pre-made L<DBI> database handle. See the example in 
the previous paragraph.

=item I<connector>

This argument allows you to supply a pre-made L<DBIx::Connector> object.

=item I<schema>

This argument allows you to supply a pre-made L<DBIx::Lite::Schema> object. If none is
provided, a new empty one will be created for each DBIx::Lite object. This argument is
useful if you want to prepare your schema in advance and reutilize it across multiple
connections.

=item I<abstract>

This argument allows you to supply options for L<SQL::Abstract::More> module. Here is 
example for MySQL DB backend to quote fields names with backtick to allow using reserved
words as column's names.

    my $dbix = DBIx::Lite->new( abstract => { quote_char => '`', name_sep => '.' } );
    $dbix->connect("DBI:mysql:$db_dbname;host=$db_host", $db_username, $db_password); 

=back

=head2 connect

This methods accepts a list of arguments that are passed to L<DBIx::Connector>. It 
returns the DBIx::Lite object. It can be called either as class or object method.

=head2 table

This method accepts a table name and returns a L<DBIx::Lite::ResultSet> object on which
you can chain its methods to build your query.

    my $rs = $dbix->table('books');

=head2 schema

This method returns our L<DBIx::Lite::Schema> object which may hold the definitions
required for some advanced feature of DBIx::Lite. You can call then call its methods:

    $dbix->schema->table('authors')->autopk('id');

See the L<DBIx::Lite::Schema> documentation for an explanation of its methods.

=head2 dbh

This method returns a L<DBI> database handle that you can use to perform manual queries.

=head2 txn

This method accepts a coderef which will be run inside a transaction.

    $dbix->txn(sub {
        $dbix->table('books')->update({ year => 2015 });
    });

=for Pod::Coverage dbh_do driver_name

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Alessandro Ranellucci.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
