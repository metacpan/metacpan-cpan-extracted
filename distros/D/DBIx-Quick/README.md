# NAME

DBIx::Quick - Object Relational Mapping for the lazy programmer

# SYNOPSIS

    package MyApp::DAO::Users;
    
    use strict;
    use warnings;
    
    use DBIx::Quick;

    table 'users';

    has dbh => (is => 'ro', required => 1);

    field id => (is => 'ro', search => 1, pk => 1);
    field username => (is => 'rw', search => 1, required => 1, column => 'user_name');
    field id_address => (is => 'rw', search => 1, fk => ['MyApp::DAO::Addresses', 'id', 'addresses', 'users']);
    field timestamp => (is => 'rw', search => 1, converter => MyApp::DB::Converters::DateTime->new);

    fix;

And elsewhere:

    my $user = MyApp::DAO::Users::Instance->new(username => 'lazybastard', id_address => 5);
    my $dao = MyApp::DAO::Users->new(dbh => DBI->connect(...));
    $dao->insert($user)
    ($user) = @{$dao->search(username => 'lazybastard')};
    $user->username('lazyandproductive');
    $dao->update($user, 'username');
    $user = $user->fetch_again; 
    $dao->delete($user);

# DESCRIPTION

[DBIx::Quick](https://metacpan.org/pod/DBIx%3A%3AQuick) is the needed bridge between [Moo](https://metacpan.org/pod/Moo) and your database, you create DAO objects in a similar fashion to [Moo](https://metacpan.org/pod/Moo) and those objects auto-create
the corresponding instances under the same package plus ::Instance, importing this module becomes your package into a [Moo](https://metacpan.org/pod/Moo) class and the created
class is also a [Moo](https://metacpan.org/pod/Moo) one.

Many times writing object to relational database mapping you find yourself having to repeat the same information once and once again which becomes
tiring for the developer, Models and DAO are created in a single step in a single file to prevent this, but they remain completely separate classes,
methods are provided to take full advantage of the separation.

The [Moo](https://metacpan.org/pod/Moo) syntax also provides shorter code overall.

This module is preliminar, meaning the syntax is probably not the definitive one, if you are a programmer who wants to spend less effort into
making full blown applications feel free to join the development with suggestions or patches.

If you are needing too fancy autocomplete or templates just to be productive maybe you instead need [DBIx::Quick](https://metacpan.org/pod/DBIx%3A%3AQuick).

To check an example project that uses this code you can check [https://github.com/sergiotarxz/Perl-App-RSS-Social](https://github.com/sergiotarxz/Perl-App-RSS-Social).

# DAO DECLARATIONS

While declaring a [DBIx::Quick](https://metacpan.org/pod/DBIx%3A%3AQuick) mapping you can use the following subs autoimported into your package namespace.

## table

    table 'transactions';

Specify the table this DAO maps to.

## field

    field id => (is => 'ro', pk => 1, search => 1);
    field amount => (is => 'ro', required => 1, search => 1, column => 'amnt');
    field tax => (is => 'ro');
    field id_user => (is => 'ro', required => 1, search => 1, fk => ['MyApp::DAO::Users', 'id', 'users', 'transactions']);

field is the equivalent to [Moo](https://metacpan.org/pod/Moo) `has` sub implementing all its options (useful or not) to represent a column into the table.

It provides the following extra options:

### pk

Defines the primary key if sent a trueish value

### search

Marks this column as searchable for the generated search method.

### column

Allows to change the destination column by default it would be called as the field itself. 

### fk

Takes four arguments: The destination class, the destination field, the method to represent in our model the remote class and optionally the remote instance method to represent our own class.

### converter

See [DBIx::Quick::Converter](https://metacpan.org/pod/DBIx%3A%3AQuick%3A%3AConverter)

## fix

Ensures the class is ready to be used and marks the class as ready.

## instance\_sub

    instance_sub uppercase_username => sub {
           my $self = shift;
           return uc($self->username);
    };

and later:

    $user->uppercase_username;

Declares a subroutine to be added to the generated ::Instance Object.

## instance\_has

    instance_has cache => (is => 'lazy');
    instance_sub _build_cache => sub {
           my $redis = Redis->new;
           return $redis;
    };

Makes a [Moo](https://metacpan.org/pod/Moo) attribute available to the ::Instance Object with the same syntax than [Moo](https://metacpan.org/pod/Moo) has.

## dbh

You must declare a dbh method or a [Moo](https://metacpan.org/pod/Moo) attribute returning a DBI connection.

# DAO METHODS

## search

    my @transactions = @{$dao->search(
           # SQL::Abstract::More where syntax using field names instead of columns
           amnt => { '>', 10000 },
           tax  => 21,
    )}

Searchs ::Instance Objects in the table using [SQL::Abstract::More](https://metacpan.org/pod/SQL%3A%3AAbstract%3A%3AMore) where syntax but replacing the column names by field names.

## free\_search

    my @transactions = @{$dao->free_search(
           -join => [
                   'users.id=transactions.id_user users',
           ],
           -where => {
                   'users.surname' => {-like => 'Gar%'},
           },
    )};

Searchs ::Instance Objects in the table using all the syntax of [SQL::Abstract::More](https://metacpan.org/pod/SQL%3A%3AAbstract%3A%3AMore) select, columns are the real columns not fields.

\-columns and -from are not allowed to be used. -from should be substituted by -join and -columns is not needed.

## insert

    $dao->insert(MyApp::DAO::Users::Instance->new(username => 'ent'));

Inserts a row in the table, doesn't return the inserted field. You can use UUIDs or other known unique attributes of the table to search for
the inserted object.

## update

    $user->username('X');
    $user->surname('González');
    $dao->update($user, 'username', 'surname');

Takes an instance and a list of the fields that should be updated in db with the instance data for that row, updates them and doesn't have a
meaningful return. Searches the object to update by the primary key.

## delete

    $dao->delete($user);

Vanishes the instance of the database. Searches by the primary key.

# INSTANCE SUBS

## fetch\_again

    $user = $user->fetch_again;

Get remote updates the ::Instance object may have.

## dbh

    $user->dbh($dbh);

Sets a database to be used in the constructor of the corresponding DAO while doing fetch\_again.

# BUGS AND LIMITATIONS

Every DAO/Instance must be associated directly with a table, if you need something extra, the good old and reliable [SQL::Abstract::More](https://metacpan.org/pod/SQL%3A%3AAbstract%3A%3AMore) is 
enough to you.

Errors must be improved to allow users to debug easier faulty code.

API is not stable since this program is so early in its development that I do not know if incorrect assumptions or bad design is hiding here.

No many to many easy wrapper, use free\_search, I could not come up with something that would be better than directly creating your own
queries with free\_search.

# AUTHOR

SERGIOXZ - Sergio Iglesias

# CONTRIBUTORS

SERGIOXZ - Sergio Iglesias

# COPYRIGHT

Copyright © Sergio Iglesias (2025)

# LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See [https://dev.perl.org/licenses/](https://dev.perl.org/licenses/).
