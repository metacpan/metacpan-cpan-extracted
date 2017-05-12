package DBIx::Mint::Schema;

use DBIx::Mint::ResultSet;
use DBIx::Mint::Schema::Class;
use Carp;
use v5.10;
use Moo;

has classes       => ( is => 'rw', default => sub {{}} );
has tables        => ( is => 'rw', default => sub {{}} );

sub instance {
    my ($class, $name) = @_;
    $name //= '_DEFAULT';
    return DBIx::Mint->instance($name)->schema;
}

sub add_class {
    my $self  = shift;
    my $class = DBIx::Mint::Schema::Class->new(@_);
    $self->classes->{$class->class}       = $class;
    $self->tables->{ $class->table}       = $class;
}

sub for_class {
    my ($self, $class) = @_;
    return $self->classes->{$class};
}

sub for_table {
    my ($self, $table) = @_;
    return $self->tables->{$table};
}

sub one_to_many {
    my ($schema, %params) = @_;

    my $conditions  = $params{ conditions }     || croak "one_to_many: join conditions are required";
    my $method      = $params{ method     }     || croak "one_to_many: method name is required";
    my $inv_method  = $params{ inverse_method } || undef;
    my $insert_into = $params{ insert_into }    || undef;
    
    $schema->add_relationship(result_as => 'all', inv_result_as => 'single', %params);

    return 1;
}

sub many_to_many {
    my ($schema, %params) = @_; 
    
    my $conditions  = $params{ conditions }     || croak "many_to_many: join conditions are required";
    my $method      = $params{ method     }     || croak "many_to_many: method name is required";
    my $inv_method  = $params{ inverse_method } || undef;
    croak "insert_into is not supported for many_to_many relationships" if $params{insert_into};
    
    $schema->add_relationship(result_as => 'all', inv_result_as => 'all', %params);

    return 1;
}

sub add_relationship {
    my ($schema, %params) = @_;
    
    # Support for from_class, to_class alternative (mainly for one-to-one associations)
    if ($params{from_class} && $params{conditions}) {
        $params{conditions} = [ $params{from_class}, $params{conditions}, $params{to_class}];
    }

    if ($params{from_class} && ! exists $params{conditions}) {
        my $pk = $schema->for_class( $params{from_class} )->pk->[0];
        $params{conditions} = [ $params{from_class}, { $pk => $params{to_field} }, $params{to_class} ];
    }
    
    
    my $conditions      = $params{ conditions }     || croak "add_relationship: join conditions are required";
    my $method          = $params{ method     }     || croak "add_relationship: method name is required";
    my $inv_method      = $params{ inverse_method } || undef;
    my $insert_into     = $params{ insert_into }    || undef;
    my $inv_insert_into = $params{ inv_insert_into} || undef;
    my $result_as       = $params{ result_as }      || undef;
    my $inv_result_as   = $params{ inv_result_as }  || undef;

    # Create method into $from_class
    my $from_class = $conditions->[0];
    my $rs = $schema->_build_rs(@$conditions);
    $schema->_build_method($rs, $from_class, $method, $result_as);
    
    # Create method into $target_class
    if (defined $inv_method) {
        my @cond_copy    = map { ref $_ ? { reverse %$_ } : $_ } reverse @$conditions;
        my $target_class = $cond_copy[0];
        my $inv_rs       = $schema->_build_rs(@cond_copy);
        $schema->_build_method($inv_rs, $target_class, $inv_method, $inv_result_as);
    }
    
    # Create insert_into method
    if (defined $insert_into) {
        my $join_cond    = $conditions->[1];
        my $target_class = $conditions->[2];
        $schema->_build_insert_into($from_class, $target_class, $insert_into, $join_cond);
    }

    return 1;
}

sub _build_rs {
    my ($schema, @conditions) = @_;
    my $from_class  = shift @conditions;
    my $from_table  = 'me';
    my $to_table;
    
    my $rs = DBIx::Mint::ResultSet->new( table => $schema->for_class( $from_class )->table  );
    
    do {
        my $from_to_fields = shift @conditions;
        my $to_class       = shift @conditions;
        my $class_obj      = $schema->for_class($to_class) || croak "Class $to_class has not been defined";
        $to_table          = $class_obj->table;
        my %join_conditions;
        while (my ($from, $to) = each %$from_to_fields) { 
            $from = "$from_table.$from";
            $to   = "$to_table.$to";
            $join_conditions{$from} = $to;
        }
        $rs = $rs->inner_join( $to_table, \%join_conditions );
        $from_table = $to_table;
    }
    while (@conditions);
    
    return $rs->select( $to_table . '.*')->set_target_class( $schema->for_table($to_table)->class );
}

sub _build_method {
    my ($schema, $rs, $class, $method, $result_as) = @_; 
    
    my @pk = @{ $schema->for_class($class)->pk };

    $result_as //= 'resultset';
    my %valid_results = (
        resultset   => 1,
        single      => 1,
        all         => 1,
        as_iterator => 1,
        as_sql      => 1
    );
    croak "result_as option not recognized for $class\::$method: '$result_as'"
        unless exists $valid_results{ $result_as };
    
    {
        no strict 'refs';
        *{$class . '::' . $method} = sub { 
            my $self = shift;
            my %conditions;
            $conditions{"me.$_"} = $self->$_ foreach @pk;
            my $rs_copy = $rs->search(\%conditions);
            if ( $result_as eq 'single' ) {
                return $rs_copy->single;      
            }
            elsif ($result_as eq 'all') {
                return $rs_copy->all;
            }
            elsif ($result_as eq 'as_iterator') { 
                return $rs_copy->as_iterator; 
            }
            elsif ($result_as eq 'as_sql') { 
                return $rs_copy->select_sql;  
            }
            else {
                return $rs_copy;
            }
        };
    }
}


sub _build_insert_into {
    my ($schema, $class, $target, $method, $conditions) = @_;
            
    no strict 'refs';
    *{$class . '::' . $method} = sub {
        my $self   = shift;
        my @copies;
        foreach my $record (@_) {
            croak "insert_into methods take hash references as input (while using $class" . "::$method)"
                unless ref $record eq 'HASH';
            while (my ($from_field, $to_field) = each %$conditions) {
                croak $class . "::" . $method .": $from_field is not defined" 
                    if !defined $self->{$from_field};
                $record->{$to_field} = $self->{$from_field};
            }
            push @copies, $record;
        }
        return $target->insert(@copies);
    };
    return 1;
}

1;

=pod

=head1 NAME

DBIx::Mint::Schema - Class and relationship definitions for DBIx::Mint

=head1 SYNOPSIS

 # Using the schema from the default Mint object:
 my $schema = DBIx::Mint->instance->schema;

 # Using a named schema:
 my $schema = DBIx::Mint::Schema->instance( 'other' );

 # which is the same as this:
 my $mint   = DBIx::Mint->instance('other');
 my $schema = $mint->schema;
 
 
 $schema->add_class(
    class => 'Bloodbowl::Coach',
    table => 'coaches',
    pk    => 'id',
    auto_pk => 1
 );
 
 $schema->one_to_many(
    conditions     => 
        [ 'Bloodbowl::Team', { id => 'team' }, 'Bloodbowl::Player' ],
    method         => 'get_players',
    inverse_method => 'get_team', 
    insert_into    => 'add_player'
 );
 
  $schema->many_to_many(
    conditions     => [ 'Bloodbowl::Player',      { id => 'player'},
                        'Bloodbowl::PlayerSkills, { skill => 'skill' },
                        'Bloodbowl::Skill' ],
    method         => 'get_skills',
    inverse_method => 'get_players'
 );

 $schema->add_relationship(
    conditions   => 
        ['Bloodbowl::Team', { id => 'team' }, 'Bloodbowl::Players'],
    method       => 'players_rs',
    result_as    => 'result_set'
 );

=head1 DESCRIPTION

This module lets you declare the mapping between classes and database tables, and it creates methods that act on the relationships you define. It is an essential part of L<DBIx::Mint>.

=head1 METHODS

=head2 add_class

Defines the mapping between a class and a database table. It expects the following arguments:

=over

=item class

The name of the class. Required.

=item table

The name of the table it points to. Required.

=item pk

Defines the primary key in the database. It can be a single field name or an array reference of field names. Required.

=item auto_pk

Lets DBIx::Mint know that the pk is automatically generated by the database. It expects a boolean value. Optional; defaults to false.

=item fields_not_in_db

Receives an array ref of attributes of the given class which are not stored in the database. They will be removed from the data before inserting or updating it into the database.

=back

=head2 one_to_many

Builds a one-to-many relationship between two classes. Internally, it is built using the method L<add_relationship>, which builds closures that contain a L<DBIx::Mint::ResultSet> object to fetch related records and, optionally, an insert_into method. It expects the following parameters:

=over

=item conditions

Defines both the classes that the relationship binds and the fields that are used to link them. These conditions are then used to build L<DBIx::Mint::ResultSet> joins.

The attribute receives an array reference with the following format:

 [ 'Class::One', { from_field => 'to_field' }, 'Class::Many' ]

one_to_many will insert a method into Class::One which will return the (many) related records of Class::Many, using from_field and to_field to link the classes.

This parameter is required.

=item method

Defines the name of the method that is inserted into the 'one' class defined in C<conditions>. This method will return a list of all the related records of the 'many' class, blessed. Required.

=item inverse_method

It creates a method in the 'many' side of the relationship that returns the related record from the 'one' side. The returned record is a blessed object. Optional.

=item insert_into

If present, this parameter defines the name of a method which is inserted into the 'one' class which allows it to insert related records into the 'many' class. It expects hash references as input. Note that they should have the same keys in order to benefit from a prepared insert statement.

=back

=head2 many_to_many

Builds a many-to-many relationship between two classes. Internally, it is built using the method L<add_relationship>, which builds closures that contain a L<DBIx::Mint::ResultSet> object to fetch related records. It expects the following parameters:

=over

=item conditions

Defines the chain of classes that the relationship binds and the fields that are used to link them. These conditions are then used to build L<DBIx::Mint::ResultSet> joins.

The attribute receives an array reference with the following format:

 [ 'Class::One', { from_field => 'to_field' }, 
   'Class::Two', { from_two   => 'to_three' },
   'Class::Three' ]

many_to_many will insert a method into Class::One which will return the (many) related records of Class::Three, joined through Class::Two. The size of the array can be arbitrarily long.

This parameter is required.

=item method

Defines the name of the method that is inserted into the first class defined in C<conditions>. This method will return a list of all the related records of the last class, blessed. Required.

=item inverse_method

It creates a method in the last class that returns a list of all the related records from the first. The records are blessed objects. Optional.

=back

=head2 add_relationship

This method creates a one-to-one, one-to-many or many-to-many relationship and it allows you to define the returned form of the resulting records.

=over

=item conditions

Same as many_to_many relationships.

=item method, inverse_method

These parameters receive the name of the methods that will be inserted into the first and last classes defined for the relationship. The difference with one_to_many and many_to_many is that, by default, you will get a L<DBIx::Mint::ResultSet> object. See result_as and inv_result_as for other options.

=item insert_into

Same as one_to_many. It will insert records into the second class you define which are related to the first class. In a many-to-many relationship that uses a single link class, this method will allow you to insert objects into the link class.

=item result_as, inv_result_as

These two parameters define the results that you will get from the created method and inverse_method. The allowed options are:

=over

=item resultset

This is the default. The method will return a L<DBIx::Mint::ResultSet> object suitable for chaining conditions or paging. It offers the most flexibility.

=item single

Methods will return a single, blessed object from your set of results.

=item all

Methods will return all the related records from your set of results.

=item as_iterator

Methods will return a L<DBIx::Mint::ResultSet> object with an iterator to fetch one record at a time from your set of results. It is used as follows:

 my $rs = $obj->method;
 while (my $record = $rs->next) {
     say $record->name;
 }

=item as_sql

This form will return the generated select SQL statement and the list of bind values. Useful for debugging.

=back

=back

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
 
