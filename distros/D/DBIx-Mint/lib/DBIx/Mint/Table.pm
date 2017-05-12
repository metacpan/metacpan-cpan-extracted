package DBIx::Mint::Table;

use DBIx::Mint;
use Carp;
use Moo::Role;

has _name => (is => 'ro', default => sub { '_DEFAULT' });

# Methods that insert data
sub create {
    my $class = shift;
    my $mint;
    if (ref $_[0] && ref $_[0] eq 'DBIx::Mint') {
        $mint = shift;
    }
    my $obj = $class->new(@_);
    $obj->insert($mint);
    return $obj;
}

sub insert {
    # Input:
    # Case 1) a class name, a Mint object, any number of hash refs to insert
    # Case 2) a class name, any number of hash refs to insert
    # Case 3) a class name, key-value pairs
    # Case 4) a blessed object and a Mint object
    # Case 5) a blessed object

    my $proto = shift;
    my $class;
    my $mint;
    my @objects;
    if (!ref $proto) {
        $class = $proto;
        if (ref $_[0] && ref $_[0] eq 'DBIx::Mint') {
           # Case 1
           $mint = shift;
           @objects = @_;
        }
        elsif (ref $_[0]) {
            # Case 2
            $mint = DBIx::Mint->instance('_DEFAULT');
            @objects = @_;
        }
        else {
            # Case 3
            $mint = DBIx::Mint->instance('_DEFAULT');
            my %data = @_;
            @objects = (\%data);
        }
     }
     else {
         $class = ref $proto;
         @objects = ($proto);
         if ($_[0] && ref $_[0] eq 'DBIx::Mint') {
             # Case 4
             $mint = shift;
         }
         else {
             # Case 5
             $mint = DBIx::Mint->instance('_DEFAULT');
         }
     }

    my $schema = $mint->schema->for_class( $class )
        || croak "A schema definition for class $class is needed to use DBIx::Mint::Table";

    # Fields that do not go into the database
    my %to_be_removed;
    @to_be_removed{ @{ $schema->fields_not_in_db } } = (1) x @{ $schema->fields_not_in_db };

    my @fields = grep {!exists $to_be_removed{$_}} keys %{ $objects[0] };
    my @quoted = map { $mint->dbh->quote_identifier( $_ ) } @fields;

    my $sql = sprintf 'INSERT INTO %s (%s) VALUES (%s)',
        $schema->table, join(', ', @quoted), join(', ', ('?') x @fields);

    my $sub = sub {
        my $sth = $_->prepare($sql);
        my @ids;
        foreach my $obj (@objects) {
            # Obtain values from the object
            my @values = @$obj{ @fields };
            $sth->execute(@values);
            if ($schema->auto_pk) {
                my $id = $_->last_insert_id(undef, undef, $schema->table, undef);
                $obj->{ $schema->pk->[0] } = $id;
            }
            push @ids, [ @$obj{ @{ $schema->pk } } ]; 
        }
        return @ids
    };
    my @ids = $mint->connector->run( fixup => $sub );
    return wantarray ? @ids : $ids[0][0];
}


sub update {
    # Input:
    # Case 1) a class name, a Mint object, two hash refs 
    # Case 2) a class name, two hash refs
    # Case 3) a blessed object

    my $proto = shift;
    my $class;
    my $mint;
    my $set;
    my $where;
    my $schema;
    if (!ref $proto) {
        $class = $proto;
        if (@_ == 3) {
            # Case 1
            ($mint, $set, $where) = @_;
            croak "DBIx::Mint::Table update: Expected the first argument to be a DBIx::Mint object "
                . "(since the three-args version was used)"
                unless ref $mint eq 'DBIx::Mint';
        }
        else {
            # Case 2
            ($set, $where) = @_;
            $mint = DBIx::Mint->instance('_DEFAULT');
        }
        $schema = $mint->schema->for_class($class)    
            || croak "A schema definition for class $class is needed to use DBIx::Mint::Table";

        croak "DBIx::Mint::Table update: called with incorrect arguments"
            unless ref $set && ref $where;
    }
    else {
        # Case 3: Updating a blessed object
        $class = ref $proto;
        my %copy = %$proto;
        $set     = \%copy;

        $mint    = DBIx::Mint->instance( $proto->_name );        
        $schema = $mint->schema->for_class($class)    
            || croak "A schema definition for class $class is needed to use DBIx::Mint::Table";

        my @pk     = @{ $schema->pk };
        my %where  = map { $_ => $proto->$_ } @pk;
        $where  = \%where;

        delete $set->{$_} foreach @{ $schema->fields_not_in_db }, @pk;
    }
    
    # Build the SQL
    my  ($sql, @bind) = $mint->abstract->update($schema->table, $set, $where);
    
    # Execute the SQL
    return $mint->connector->run( fixup => sub { $_->do($sql, undef, @bind) } );
}

sub delete {
    # Input:
    # Case 1) a class name, a Mint object, a data hash ref
    # Case 2) a class name, a data hash ref
    # Case 3) a class name, a list of scalars (primary key values)
    # Case 4) a blessed object
    
    my $proto = shift;
    my $class;
    my $data;
    my $mint;
    if (!ref $proto) {
        $class = $proto;
        if (ref $_[0] eq 'DBIx::Mint') {
            # Case 1
            ($mint, $data) = @_;
        }
        elsif (ref $_[0]) {
            # Case 2
            $data = shift;
            $mint = DBIx::Mint->instance('_DEFAULT');
        }
        else {
            # Case 3
            my %data = @_;
            $data = \%data;
            $mint = DBIx::Mint->instance('_DEFAULT');
        }
    }
    else {
        # Case 4
        $class   = ref $proto;
        my %data = %$proto;
        $data    = \%data;
        my $name = delete $data->{_name} || '_DEFAULT';
        $mint    = DBIx::Mint->instance($name);
    }
    
    my $schema = $mint->schema->for_class($class)    
        || croak "A schema definition for class $class is needed to use DBIx::Mint::Table";

    # Build the SQL
    my ($sql, @bind) = $mint->abstract->delete($schema->table, $data);
    my $conn = $mint->connector;
    my $res = $conn->run( fixup => sub { $_->do($sql, undef, @bind) } );
    if (ref $proto && $res) {
        %$proto = ();
    }
    return $res;
}

# Returns a single, inflated object using its primary keys
sub find {
    my $class = shift;
    croak "find must be called as a class method" if ref $class;
    
    # Input:
    # Case 1) a Mint object, a data hash ref
    # Case 2) a Mint object, a list of scalars (primary key values)
    # Case 3) a data hash ref
    # Case 4) a list of scalars (primary key values) 
    my $data;
    my $mint;
    my $schema;
    if (ref $_[0] && ref $_[0] eq 'DBIx::Mint') {
        $mint   = shift;
        $schema = $mint->schema->for_class($class);
        if (ref $_[0]) {
            # Case 1
            $data   = shift;
        }
        else {
            # Case 2
            my @pk   = @{ $schema->pk };
            my %data;
            @data{@pk} = @_;
            $data = \%data;
        }
    }
    else {
        $mint   = DBIx::Mint->instance('_DEFAULT');
        $schema = $mint->schema->for_class($class);
        if (ref $_[0]) {
            # Case 3
            $data = shift;
        }
        else {
            # Case 4
            my @pk   = @{ $schema->pk };
            my %data;
            @data{@pk} = @_;
            $data = \%data;
        }
    }

    my $table  = $schema->table;    
    my ($sql, @bind) = $mint->abstract->select($table, '*', $data);
    
    # Execute the SQL
    my $res = $mint->connector->run( fixup => sub { $_->selectall_arrayref($sql, {Slice => {}}, @bind) } );
    return undef unless defined $res->[0];

    $res->[0]->{_name} = $mint->name;
    my $obj = bless $res->[0], $class;
    return $obj;
}

sub find_or_create {
    my $class = shift;
    my $mint;
    if (ref $_[0] eq 'DBIx::Mint') {
        $mint = shift;
    }
    else {
        $mint = DBIx::Mint->instance;
    }
    my $obj = $class->find($mint, @_);
    $obj = $class->create($mint, @_) if ! defined $obj;
    return $obj;
}

sub result_set {
    my ($class, $instance) = @_;
    my $mint;
    if (ref $instance) { 
        $mint = $instance;
    }
    else {
        $instance //= '_DEFAULT';
        $mint = DBIx::Mint->instance($instance);
    }
    
    my $schema = $mint->schema->for_class($class);
    croak "result_set: The schema for $class is undefined" unless defined $schema;
    return DBIx::Mint::ResultSet->new( table => $schema->table, instance => $mint->name );
}

1;

=pod

=head1 NAME 

DBIx::Mint::Table - Role that maps a class to a table

=head1 SYNOPSIS

 # In your class:
 
 package Bloodbowl::Coach;
 use Moo;
 with 'DBIx::Mint::Table';
 
 has 'id'     => ( is => 'rwp', required => 1 );
 has 'name'   => ( is => 'ro',  required => 1 );
 ....
 
 # And in your schema:
 $schema->add_class(
    class   => 'Bloodbowl::Coach',
    table   => 'coaches',
    pk      => 'id',
    auto_pk => 1
 );
 
 # Finally, in your application:
 my $coach = Bloodbowl::Coach->find(3);
 say $coach->name;
 
 $coach->name('Will E. Coyote');
 $coach->update;
 
 my @ids = Bloodbowl::Coach->insert(
    { name => 'Coach 1' },
    { name => 'Coach 2' },
    { name => 'Coach 3' }
 );
 
 $coach->delete;
 
 my $coach = Bloodbowl::Coach->find_or_create(3);
 say $coach->id;
 
 # The following two lines are equivalent:
 my $rs = Bloodbowl::Coach->result_set;
 my $rs = DBIx::Mint::ResultSet->new( table => 'coaches' );

=head1 DESCRIPTION

This role allows your class to interact with a database table. It allows for record modification (insert, update and delete records) as well as data fetching (find and find_or_create) and access to DBIx::Mint::ResultSet objects.

Database modification methods can be called as instance or class methods. In the first case, they act only on the calling object. When called as class methods they allow for the modification of several records.

Triggers can be added using the methods before, after, and around from L<Class::Method::Modifiers>.

The database modifying parts of the routines are run under DBIx::Connector's fixup mode, as they are so small that no side-effects are expected. If you use transactions, the connection will be checked only at the outermost block method call. See L<DBIx::Connector> for more information.

=head1 METHODS

=head2 create

This methods is a convenience that calls new and insert to create a new object. The following two lines are equivalent:

 my $coach = Bloodbowl::Coach->create( name => 'Will E. Coyote');
 my $coach = Bloodbowl::Coach->new( name => 'Will E. Coyote')->insert;

Or, using a different database connection:

 my $mint  = DBIx::Mint->instance('other');
 my $coach = Bloodbowl::Coach->create( $mint, name => 'Will E. Coyote');

=head2 insert

When called as a class method, it takes a list of hash references and inserts them into the table which corresponds to the calling class. The hash references must have the same keys to benefit from a prepared statement holder. The list of fields is taken from the first record. If only one record is used, it can be simply a list of key-value pairs.

When called as an instance method, it inserts the data contained within the object into the database.

 # Using the default DBIx::Mint object:
 
 Bloodbowl::Coach->insert( name => 'Bruce Wayne' );
 Bloodbowl::Coach->insert(
    { name => 'Will E. Coyote' },
    { name => 'Clark Kent'     },
    { name => 'Peter Parker'   });

 $batman->insert;

Additionally, it can be given an alternative DBIx::Mint object to act on a connection other than the default one:

 # Using a given DBIx::Mint object:
 Bloodbowl::Coach->insert( $mint,
    { name => 'Will E. Coyote' },
    { name => 'Clark Kent'     },
    { name => 'Peter Parker'   });

 $batman->insert($mint);

=head2 update

When called as a class method it will act over the whole table. The first argument defines the change to update and the second, the conditions that the records must comply with to be updated:

 Bloodbowl::Coach->update( { email => 'unknown'}, { email => undef });
 
When called as an instance method it updates only the record that corresponds to the calling object:

 $coach->name('Mr. Will E. Coyote');
 $coach->update;

To use a DBIx::Mint instance other than the default one:

 my $mint = DBIx::Mint->instance('database_2');
 Bloodbowl::Coach->update( { email => 'unknown'}, { email => undef }, $mint);

=head2 delete

This method deletes information from the corresponding table. When called as a class method it acts on the whole table; when called as an instance method it deletes the calling object from the database:

 Bloodbowl::Coach->delete({ email => undef });
 Bloodbowl::Team->delete( name => 'Tinieblas');
 $coach->delete;

The statements above delete information using the default database connection. If a named DBIx::Mint instance is needed:

 my $mint = DBIx::Mint->instance('database_2');
 Bloodbowl::Coach->delete({ email => undef }, $mint);

=head2 find

Fetches a single record from the database and blesses it into the calling class. It can be called as a class record only. It can as take as input either the values of the primary keys for the corresponding table or a hash reference with criteria to fetch a single record:

 my $coach_3 = Bloodbowl::Coach->find(3);
 my $coach_3 = Bloodbowl::Coach->find({ name => 'coach 3'});

To use a named DBIx::Mint instance:

 my $mint = DBIx::Mint->instance('database_2');
 my $coach_3 = Bloodbowl::Coach->find({ id => 3 }, $mint);

=head2 find_or_create

This method will call 'create' if the requested record is not found in the database.

 my $obj = Bloodbowl::Coach->find_or_create(
    name => 'Bob', email => 'bob@coaches.net'
 );
 my $obj = Bloodbowl::Coach->find_or_create(
    $mint, { name => 'Bob', email => 'bob@coaches.net' }
 );

=head2 result_set

Get a L<DBIx::Mint::ResultSet> object for the table associated with this class. Optionally, use a named Mint object:

 my $rs = Bloodbowl::Team->result_set;            # With default db
 my $rs = Bloodbowl::Team->result_set('other');   # With other db

=head1 SEE ALSO

This module is part of L<DBIx::Mint>.

=head1 AUTHOR

Julio Fraire, <julio.fraire@gmail.com>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Julio Fraire. All rights reserved.

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
 
