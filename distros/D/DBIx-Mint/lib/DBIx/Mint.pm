package DBIx::Mint;

use DBIx::Mint::Singleton;
use DBIx::Connector;
use DBIx::Mint::Schema;
use SQL::Abstract::More;
use Carp;
use Moo;

our $VERSION = 0.071;

has name       => ( is => 'ro', default   => sub { '_DEFAULT' } );
has abstract   => ( is => 'rw', default   => sub { SQL::Abstract::More->new(); } );
has schema     => ( is => 'rw', default   => sub { return DBIx::Mint::Schema->new } );
has connector  => ( is => 'rw', predicate => 1 );

sub BUILD {
    my $self = shift;
    my $singleton = DBIx::Mint::Singleton->instance;
    croak "DBIx::Mint object " . $self->name . " exists already"
        if $singleton->exists($self->name);
    $singleton->add_instance($self);
}

sub instance {
    my ($class, $name) = @_;
    $name //= '_DEFAULT';
    my $singleton = DBIx::Mint::Singleton->instance;
    if (!$singleton->exists($name)) {
        $class->new( name => $name );
    }
    return $singleton->get_instance($name);
}

sub dbh {
    my $self = shift;
    return  $self->has_connector ? $self->connector->dbh
        : croak 'Please feed DBIx::Mint with a database connection';
};

sub connect {
    my ($self, $dsn, $username, $passwd, $args) = @_;
    if (ref $_[0]) {
        $self = shift;
    }
    else {
        my $class = shift;
        $self = $class->instance();
    }
    $args->{HandleError} //= sub { croak $_[0] };
    $self->connector( DBIx::Connector->new(
        $dsn, $username, $passwd, $args ) );
    $self->connector->mode('ping');

    return $self;
}

sub do_transaction {
    my ($self, $trans) = @_;

    my $auto = $self->dbh->{AutoCommit};
    $self->dbh->{AutoCommit} = 0 if $auto;

    my @output;    
    eval { @output = $self->connector->txn( $trans ) };

    if ($@) {
        carp "Transaction failed: $@";
        $self->dbh->rollback;
        $self->dbh->{AutoCommit} = 1 if $auto;
        return undef;
    }
    $self->dbh->{AutoCommit} = 1 if $auto;
    return @output ? @output : 1;
}

1;

=pod

=head1 NAME

DBIx::Mint - A mostly class-based ORM for Perl

=head1 VERSION

This documentation refers to DBIx::Mint 0.071

=head1 SYNOPSIS

Define your classes, which will play the role L<DBIx::Mint::Table>:

 package Bloodbowl::Team;
 use Moo;
 with 'DBIx::Mint::Table';
 
 has id   => (is => 'rw' );
 has name => (is => 'rw' );
 ...

Nearby (probably in a module of its own), you define the schema for your classes:

 package Bloodbowl::Schema;

 my $schema = DBIx::Mint->instance->schema;
 $schema->add_class(
     class      => 'Bloodbowl::Team',
     table      => 'teams',
     pk         => 'id',
     auto_pk    => 1,
 );
 
 $schema->add_class(
     class      => 'Bloodbowl::Player',
     table      => 'players',
     pk         => 'id',
     auto_pk    => 1,
 );
 
 # This is a one-to-many relationship
 $schema->one_to_many(
     conditions     => 
        ['Bloodbowl::Team', { id => 'team'}, 'Bloodbowl::Player'],
     method         => 'get_players',
     inverse_method => 'get_team',
 );

And in your your scripts:
 
 use DBIx::Mint;
 use My::Schema;
 
 # Connect to the database
 DBIx::Mint->connect( $dsn, $user, $passwd, { dbi => 'options'} );
 
 my $team    = Bloodbowl::Team->find(1);
 my @players = $team->get_players;
 
 # Database modification methods include insert, update, and delete.
 # They act on a single object when called as instance methods
 # but over the whole table if called as class methods:
 $team->name('Los Invencibles');
 $team->update;
 
 Bloodbowl::Coach->update(
    { status   => 'suspended' }, 
    { password => 'blocked' });
 
Declaring the schema allows you to modify the data. To define a schema and to learn about data modification methods, look into L<DBIx::Mint::Schema> and L<DBIx::Mint::Table>. 

If you only need to query the database, no schema is needed. L<DBIx::Mint::ResultSet> objects build database queries and fetch the resulting records:
  
 my $rs = DBIx::Mint::ResultSet->new( table => 'coaches' );
 
 # You can perform joins:
 my @team_players = $rs->search( { 'me.id' => 1 } )
   ->inner_join( 'teams',   { 'me.id'    => 'coach' })
   ->inner_join( 'players', { 'teams.id' => 'team'  })
   ->all;
 
=head1 DESCRIPTION

DBIx::Mint is a mostly class-based, object-relational mapping module for Perl. It tries to be simple and flexible, and it is meant to integrate with your own custom classes.

Since version 0.04, it allows for multiple database connections and it features L<DBIx::Connector> objects under the hood. This should make DBIx::Mint easy to use in persistent environments.

There are many ORMs for Perl. Most notably, you should look at L<DBIx::Class> and L<DBIx::DataModel> which are two robust, proven offerings as of today. L<DBIx::Lite> is another light-weight alternative.

=head1 DOCUMENTATION

The documentation is split into four parts:

=over

=item * This general view, which documents the umbrella class DBIx::Mint. A DBIx::Mint object encapsulates a given database conection and its schema.

=item * L<DBIx::Mint::Schema> documents the mapping between classes and database tables. It shows how to specify table names, primary keys and how to create associations between classes.

=item * L<DBIx::Mint::Table> is a role that allows you to modify or fetch data from a single table. It is meant to be applied to your custom classes using L<Moo> or L<Role::Tiny::With>.

=item * L<DBIx::Mint::ResultSet> performs database queries using chainable methods. It does not know about the schema, so it can be used without one or without any external classes .

=back

=head1 GENERALITIES

The basic idea is that, frequently, a class can be mapped to a database table. Records become objects that can be created, fetched, updated and deleted. With the help of a schema, classes know what database table they represent, as well as their primary keys and the relationships they have with other classes. Relationships between classes are represented as methods that act upon objects from other classes, for example, or that simply return data. Using such a schema and a table-accessing role, classes gain database persistence.

Fetching data from joined tables is different, though. While you can have a class to represent records comming from a join, you cannot create, update or delete directly the objects from such a class. Using L<DBIx::Mint::ResultSet> objects, complex table joins and queries are encapsulated, along with different options to actually fetch data and possibly bless it into full-blown objects. In this case, DBIx::Mint uses the result set approach, as DBIx::Lite does.

Finally, DBIx::Mint objects contain the database connection, the database schema and its SQL syntax details. Because each object encapsulates a database connection, you may create several objects to interact with different databases within your program. Mint objects are kept in a centralized pool so that they remain accessible without the need of passing them through explicitly.

=head1 SUBROUTINES/METHODS IMPLEMENTED BY L<DBIx::Mint>

=head2 new

First of three constructors. All of them will save the newly created object into the connection pool, but they will croak if the object exists already. All the arguments to C<new> are optional. If C<abstract> or C<connector> are not given, the objects will be created for you with their default arguments.

=over

=item name

The name of the new Mint object. Naming your objects allows for having more than one, and thus for having simultaneus connections to different databases. The object name will be used to fetch it from the connections pool (see the method L<DBIx::Mint::instance|instance>).

=item schema

A L<DBIx::Mint::Schema> object. You can create the DBIx::Mint::Schema yourself and feed it into different DBIx::Mint objects to use the same schema over different databases.

=item abstract

A L<SQL::Abstract::More> object.

=item connector

A L<DBIx::Connector> object.

=back

=head2 connect

Connects the Mint object to the database. If called as a class method, C<connect> creates a Mint object with the default name first. It receives your database connection parameters per L<DBI>'s specifications:

 # Create the default Mint object and its connection:
 DBIx::Mint->connect('dbi:SQLite:dbname=t/bloodbowl.db', $username, $password,
        { AutoCommit => 1, RaiseError => 1 });

 # Create a named connection:
 my $mint = DBIx::Mint->new( name => 'other' );
 $mint->connect('dbi:SQLite:dbname=t/bloodbowl.db', '', '',
        { AutoCommit => 1, RaiseError => 1 });

=head2 instance

Class method. It fetches an instance of L<DBIx::Mint> from the object pool:

 my $mint  = DBIx::Mint->instance;           # Default connection
 my $mint2 = DBIx::Mint->instance('other');  # 'other' connection

If the object does not exist, it will be created and so this is the third constructor. This method allows you to create mappings to different databases in the same program. The optional argument is used as the DBIx::Mint object name.

=head2 connector

This accessor/mutator will return the underlying L<DBIx::Connector> object.

=head2 dbh

This method will return the underlying database handle, which is guaranteed to be alive.
 
=head2 abstract

This is the accessor/mutator for the L<SQL::Abstract::More> subjacent object.

=head2 schema

This is the accessor/mutator for the L<DBIx::Mint::Schema> instance.

=head2 do_transaction

This instance method will take a code reference and execute it within a transaction block. In case the transaction fails (your code dies) it is rolled back and B<a warning is thrown>. In this case, L<do_transaction> will return C<undef>. If successful, the transaction will be commited and the method will return a true value. 

 $mint->do_transaction( $code_ref ) || die "Transaction failed!";

Note that it must be called as an intance method, not as a class method.
 
=head1 USE OF L<DBIx::Connector>

Under the hood, DBIx::Mint uses DBIx::Connector to hold the database handle and to make sure that the connection is well and alive when you need it. The database modification routines employ the 'fixup' mode for modifying the database at a very fine-grained level, so that no side-effects are visible. This allows us to use DBIx::Connector in an efficient way. If you choose to install method modifiers around database interactions, be careful to avoid unwanted secondary effects.

The query routines offered by L<DBIx::Mint::ResultSet> use the 'fixup' mode while retrieving the statement holder with the SELECT query already prepared, but not while extracting information in the execution phase. If you fear that the database connection may have died in the meantime, you can always use Mint's C<connector> method to get a hold of the DBIx::Connector object and manage the whole query process yourself. This should not be necessary, though.

=head1 DEPENDENCIES

This distribution depends on the following external, non-core modules:

=over

=item Moo

=item MooX::Singleton

=item SQL::Abstract::More

=item DBI

=item DBIx::Connector

=item List::MoreUtils

=item Clone

=back

=head1 BUGS AND LIMITATIONS

Testing is not complete; in particular, tests look mostly for the expected results and not for edge cases or plain incorrect input. 

Please report problems to the author. Patches are welcome. Tests are welcome also.

=head1 ACKNOWLEDGEMENTS

The ResultSet class was inspired by L<DBIx::Lite>, by Alessandro Ranellucci.

=head1 AUTHOR

Julio Fraire, <julio.fraire@gmail.com>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Julio Fraire. All rights reserved.

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
