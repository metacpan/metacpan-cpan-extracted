package Coat::Persistent;

# Coat & friends
use Coat;
use Coat::Meta;
use Coat::Persistent::Meta;
use Coat::Persistent::Constraint;
use Carp 'confess';

use Data::Dumper;

# Low-level helpers
use Digest::MD5 qw(md5_base64);
use Scalar::Util qw(blessed looks_like_number);
use List::Compare;

# DBI & SQL related
use DBI;
use DBIx::Sequence;
use SQL::Abstract;

# Constants
use constant CP_ENTRY_NEW => 0;
use constant CP_ENTRY_EXISTS => 1;

# Module meta-data
use vars qw($VERSION @EXPORT $AUTHORITY);
use base qw(Exporter);

$VERSION   = '0.223';
$AUTHORITY = 'cpan:SUKRIA';
@EXPORT    = qw(has_p has_one has_many);

# The SQL::Abstract object
my $sql_abstract = SQL::Abstract->new;

# configuration place-holders
my $MAPPINGS    = {};

# static accessors
sub mappings { $MAPPINGS }
sub dbh { 
    $MAPPINGS->{'!dbh'}{ $_[0] }    || 
    $MAPPINGS->{'!dbh'}{'!default'} ||
    undef
}
sub driver {
    $MAPPINGS->{'!driver'}{ $_[0] }    || 
    $MAPPINGS->{'!driver'}{'!default'} ||
    undef;
}
sub cache {
    $MAPPINGS->{'!cache'}{ $_[0] }    ||
    $MAPPINGS->{'!cache'}{'!default'} || 
    undef;
}


# The internel sequence engine (DBIx::Sequence)
# If disabled, nothing will be done for the primary keys, their values
# should be set by the underlying DB.
my $USE_INTERNAL_SEQUENCE_ENGINE = 1;
sub has_internal_sequence_engine     { $USE_INTERNAL_SEQUENCE_ENGINE }
sub enable_internal_sequence_engine  { $USE_INTERNAL_SEQUENCE_ENGINE = 1 }
sub disable_internal_sequence_engine { $USE_INTERNAL_SEQUENCE_ENGINE = 0 }

# Access to the constraint meta data for the current class
sub has_unique_constraint {
    my ($class, $attr) = @_;
    $class->has_constraint($attr, 'unique');
}

sub has_constraint {
    my ($class, $attr, $constraint) = @_;
    Coat::Persistent::Constraint->get_constraint($constraint, $class, $attr) || 0;
}

sub enable_cache {
    my ($class, %options) = @_;
    $class = '!default' if $class eq 'Coat::Persistent';

    # first, try to use Cache::FastMmap
    eval "use Cache::FastMmap";
    confess "Unable to load Cache::FastMmap : $@" if $@;

    # importing the module
    Cache::FastMmap->import;

    # default cache configuration
    $options{expire_time} ||= '1h';
    $options{cache_size}  ||= '10m';

    $MAPPINGS->{'!cache'}{$class} = Cache::FastMmap->new( %options );
}

sub disable_cache {
    my ($class) = @_;
    $class = '!default' if $class eq 'Coat::Persistent';
    undef $MAPPINGS->{'!cache'}{$class};
}

# A singleton that stores the driver/module mappings
# The ones here are default drivers that are known to be compliant
# with Coat::Persistent.
# Any DBI driver should work though.
my $drivers = {
    csv    => 'DBI:CSV',
    mysql  => 'dbi:mysql',
    sqlite => 'dbi:SQLite',
};
sub drivers { $drivers }

# Accessor to a driver
sub get_driver {
    my ($class, $driver) = @_;
    confess "driver needed" unless $driver;
    return $class->drivers->{$driver};
}

# This lets you add the DBI driver you want to use
sub add_driver {
    my ($class, $driver, $module) = @_;
    confess "driver and module needed" unless $driver and $module;
    $class->drivers->{$driver} = $module;
}

# This is the configration stuff, you basically bind a class to
# a DBI driver
sub map_to_dbi {
    my ( $class, $driver, @options ) = @_;
    confess "Static method cannot be called from instance" if ref $class;
    my $connect_options = {  PrintError => 0, RaiseError => 0 };

    # if map_to_dbi is called from Coat::Persistent, this is the default dbh
    $class = '!default' if $class eq 'Coat::Persistent';

    my $drivers = Coat::Persistent->drivers;

    
    confess "No such driver : $driver, please register the driver first with add_driver()"
      unless exists $drivers->{$driver};

    # the csv driver needs to load the appropriate DBD module
    if ($driver eq 'csv') {
        eval "use DBD::CSV 0.22";
        confess "Unable to load DBD::CSV : $@" if $@;
        DBD::CSV->import;
        $connect_options->{csv_null} = 1; # since version 0.25 we have to do that to preserve undef values
    }

    $MAPPINGS->{'!driver'}{$class} = $driver;

    my ( $table, $user, $pass ) = @options;
    $driver = $drivers->{$driver};
    $MAPPINGS->{'!dbh'}{$class} =
      DBI->connect( "${driver}:${table}", $user, $pass, $connect_options);
       
    confess "Can't connect to database ${DBI::err} : ${DBI::errstr}"
        unless $MAPPINGS->{'!dbh'}{$class};

    # if the DBIx::Sequence tables don't exist, create them
    _create_dbix_sequence_tables($MAPPINGS->{'!dbh'}{$class}) if has_internal_sequence_engine();
}

# This is used if you already have a dbh instead of creating one with 
# map_to_dbi 
sub set_dbh {
    my ($class, $driver, $dbh) = @_;
    confess "Cannot set an undefined dbh" 
        unless defined $dbh;
    confess "Driver '$driver' is not supported" 
        unless defined exists $class->drivers->{$driver};

    $class = '!default' if $class eq 'Coat::Persistent';
    $MAPPINGS->{'!dbh'}{$class} = $dbh;
    $MAPPINGS->{'!driver'}{$class} = $driver;
    
    _create_dbix_sequence_tables($MAPPINGS->{'!dbh'}{$class}) 
        if has_internal_sequence_engine();
}

# This is done to wrap the original Coat::has method so we can
# generate finders for each attribute declared
# 
# ActiveRecord chose to make attribute's finders dynamic, the functions are built
# at runtime whenever they're called. In Perl this could have been done with 
# AUTOLOAD, but that sucks. Doing that would mean crappy performances;
# defining the method in the package's namespace is far more efficient.
#
# The only case where I see AUTOLOAD is the good choice is for finders
# made by mixing more than one attribute (find_by_foo_and_bar). 
# Then, yes AUTOLOAD is a good choice, but for all the ones we know we need 
# them, I disagree.
sub has_p {
    my ( $attr, %options ) = @_;
    my $caller = $options{'!caller'} || caller;
    confess "package main called has_p" if $caller eq 'main';

    # unique field ?
    if ($options{'unique'}) {
        Coat::Persistent::Constraint->add_constraint('unique', $caller, $attr, 1);
    }
    
    # specific storage type ?
    if ($options{'store_as'}) {
        # We need bi-directional coercion for this "store_as" feature ...
        my $storage_type = Coat::Types::find_type_constraint($options{'store_as'});
        confess "Unknown type \"".$options{'store_as'}."\" for storage" 
            unless defined $storage_type;
        confess "No coercion defined for storage type \"".$options{'store_as'}."\""
            unless $storage_type->has_coercion;

        my $type = Coat::Types::find_type_constraint($options{isa});
        confess "No cercion for attribute type : \"".$options{isa}."\"" 
            unless $type->has_coercion;

        Coat::Persistent::Constraint->add_constraint('store_as', $caller, $attr, $options{'store_as'});
        $options{coerce} = 1;
    }

    Coat::has( $attr, ( '!caller' => $caller, %options ) );
    Coat::Persistent::Meta->attribute($caller, $attr);

    # find_by_
    my $sub_find_by = sub {
        my ( $class, $value ) = @_;
        confess "Cannot be called from an instance" if ref $class;
        confess "Cannot find without a value" unless defined $value;
        my $table = Coat::Persistent::Meta->table_name($class);
        my ($sql, @values) = $sql_abstract->select($table, '*', {$attr => $value});
        return $class->find_by_sql($sql, @values);
    };
    _bind_code_to_symbol( $sub_find_by, 
                          "${caller}::find_by_${attr}" );

    # find_or_create_by_
    my $sub_find_or_create = sub {

        # if 2 args : we're given the value of $attr only
        if (@_ == 2) {
            my ($class, $value) = @_;
            my $obj = $class->find(["$attr = ?", $value]);
            return $obj if defined $obj;
            $class->create($attr => $value);
        }
        # more than 2 args : this is a hash of attributes to look for
        else {
            my ($class, %attrs) = @_;
            confess "Cannot find_or_create_by_$attr without $attr" 
                unless exists $attrs{$attr};
            my $obj = $class->find(["$attr = ?", $attrs{$attr}]);
            return $obj if defined $obj;
            $class->create(%attrs);
        }
    };
    _bind_code_to_symbol( $sub_find_or_create, 
                          "${caller}::find_or_create_by_${attr}" );

    # find_or_initialize_by_
    my $sub_find_or_initialize = sub {
        # if 2 args : we're given the value of $attr only
        if (@_ == 2) {
            my ($class, $value) = @_;
            my $obj = $class->find(["$attr = ?", $value]);
            return $obj if defined $obj;
            $class->new($attr => $value);
        }
        # more than 2 args : this is a hash of attributes to look for
        else {
            my ($class, %attrs) = @_;
            confess "Cannot find_or_initialize_by_$attr without $attr" 
                unless exists $attrs{$attr};
            my $obj = $class->find(["$attr = ?", $attrs{$attr}]);
            return $obj if defined $obj;
            $class->new(%attrs);
        }
    };
    _bind_code_to_symbol( $sub_find_or_initialize, 
                          "${caller}::find_or_initialize_by_${attr}" );
}

# let's you define a relation like A.b_id -> B
# this will builds an accessor called "b" that will
# do a B->find(A->b_id)
# example :
#   package A;
#   ...
#   has_one 'foo';
#   ...
#   my $a = new A;
#   my $f = $a->foo
#
# TODO : later let the user override the bindings

sub has_one {
    my ($name, %options) = @_;
    my $class = caller;

    my $owned_class       = $options{class_name} || $name;
    my $owned_table_name  = Coat::Persistent::Meta->table_name($owned_class);
    my $owned_primary_key = Coat::Persistent::Meta->primary_key($owned_class);

    confess "The class \"$owned_class\" does not have a primary key."
        unless defined $owned_primary_key;
    
    my $attr_name = (defined $options{class_name}) ? $name : $owned_table_name ;

    # record the foreign key
    my $foreign_key = $options{foreign_key} || ($owned_table_name . '_' .  $owned_primary_key);
    has_p $foreign_key => ( isa => 'Int', '!caller' => $class );

    my $symbol = "${class}::${attr_name}";
    my $code   = sub {
        my ( $self, $object ) = @_;

        # want to set the subobject
        if ( @_ == 2 ) {
            if ( defined $object ) {
                $self->$foreign_key( $object->$owned_primary_key );
            }
            else {
                $self->$foreign_key(undef);
            }
        }

        # want to get the subobject
        else {
            return undef unless defined $self->$foreign_key;
            $owned_class->find( $self->$foreign_key );
        }
    };
    _bind_code_to_symbol( $code, $symbol );

    # save the accessor defined for that subobject
    Coat::Persistent::Meta->accessor( $class => $attr_name );
}

# many relations means an instance of class A owns many instances
# of class B:
#     $a->bs returns B->find_by_a_id($a->id)
# * B must provide a 'has_one A' statement for this to work
sub has_many {
    my ($name, %options)   = @_;
    my $class = caller;

    my $owned_class       = $options{class_name} || $name;

    # get the SQL table names and primary keys we need 
    my $table_name        = Coat::Persistent::Meta->table_name($class);
    my $primary_key       = Coat::Persistent::Meta->primary_key($class);
    my $owned_table_name  = Coat::Persistent::Meta->table_name($owned_class);
    my $owned_primary_key = Coat::Persistent::Meta->primary_key($owned_class);
    
    confess "The class \"$owned_class\" does not have a primary key."
        unless defined $owned_primary_key;
    
    
    my $attr_name = (defined $options{class_name}) 
                  ? $name 
                  : $owned_table_name.'s' ;

    # FIXME : have to pluralize properly and let the user
    # disable the pluralisation.
    # the accessor : $obj->things for subobject "Thing"
    my $code = sub {
        my ( $self, @list ) = @_;

        # a get
        if ( @_ == 1 ) {
            my $accessor = "find_by_${table_name}_${primary_key}";
            return $owned_class->$accessor( $self->$primary_key );
        }

        # a set
        else {
            foreach my $obj (@list) {
                # is the object made of something appropriate?
                confess "Not an object reference, expected $owned_class, got ($obj)"
                  unless defined blessed $obj;
                confess "Not an object of class $owned_class (got "
                  . blessed($obj) . ")"
                  unless blessed $obj eq $owned_class;
                
                # then set 
                my $accessor = Coat::Persistent::Meta->accessor( $owned_class) || $table_name;
                $obj->$accessor($self);
                push @{ $self->{_subobjects} }, $obj;
            }
            return scalar(@list) == scalar(@{$self->{_subobjects}});
        }
    };
    _bind_code_to_symbol( $code, "${class}::${attr_name}" );
}

# When Coat::Persistent is imported, a couple of actions have to be 
# done. Mostly: declare the default primary key of the model, the table
# name it maps.
sub import {
    my ($class, @stuff) = @_;
    my %options;
    %options = @stuff if @stuff % 2 == 0;

    # Don't do our automagick inheritance if main is calling us or if the
    # class has already been registered
    my $caller = caller;
    return if $caller eq 'main';
    return if defined Coat::Persistent::Meta->registry( $class );
    
    # now, our caller inherits from Coat::Persistent
    eval { Coat::_extends_class( ['Coat::Persistent'], $caller ) };

    # is the primary_key disabled?
    if (exists($options{primary_key}) && (not defined $options{primary_key})) {
        $options{primary_key} = undef;
    }
    else {
        $options{primary_key} ||= 'id';
    }

    # the table_name if not defined is taken from the model name
    $options{table_name}  ||= $caller->_to_sql;

    # save the meta information obout the model mapping
    Coat::Persistent::Meta->table_name($caller, $options{table_name});
    Coat::Persistent::Meta->primary_key($caller, $options{primary_key});

    # if the primary_key is defined
    if (defined $options{primary_key}) {
        has_p $options{primary_key} => ( isa => 'Int', '!caller' => $caller );
    }

    # we have a couple of symbols to export outside
    Coat::Persistent->export_to_level( 1, ($class, @EXPORT) );
}

# find() is a polymorphic method that can behaves in several ways accroding 
# to the arguments passed.
#
# Class->find() : returns all rows (select * from class)
# Class->find(12) : returns the row where id = 12
# Class->find("condition") : returns the row(s) where condition
# Class->find(["condition ?", $val]) returns the row(s) where condition
#
# You can also pass an as your last argument, this will be the options
# Class->find(..., \%options) 

sub find {
    # first of all, if the last arg is a HASH, its our options
    # then, pop it so it's not processed anymore.
    my %options;
    %options = %{ pop @_ } 
        if (defined $_[$#_] && ref($_[$#_]) eq 'HASH');

    # then, fetch the args
    my ( $class, $value, @rest ) = @_;
    confess "Cannot be called from an instance" if ref $class;

    # get the corresponfing SQL names
    my $primary_key = Coat::Persistent::Meta->primary_key($class);
    my $table_name  = Coat::Persistent::Meta->table_name($class);

    # handling of the options given
    my $select = $options{'select'} || '*';
    my $from   = $options{'from'}   || $table_name;
    my $group  = "GROUP BY " . $options{group} if defined $options{group};
    my $order  = "ORDER BY " . $options{order} if defined $options{order};
    my $limit  = "LIMIT "    . $options{limit} if defined $options{limit};

    
    # now building the sql tail of our future query
    my $tail = " ";
    $tail   .= "$group " if defined $group;
    $tail   .= "$order " if defined $order;
    $tail   .= "$limit " if defined $limit;

    if (defined $value) {
        if (ref $value) {
            confess "Cannot handle non-array references" if ref($value) ne 'ARRAY';
            # we don't use SQL::Abstract there, because we have a SQL
            # statement with "?" and a list of values
            my ($sql, @values) = @$value;
            $class->find_by_sql(
                "select $select from $from where $sql $tail", @values);
        }
        # we don't have a list, so let's find out what's given 
        else {
            # the first item looks like a number (then it's an ID)
            if (looks_like_number $value) {
                
                # can I haz primary_key?
                confess "Cannot use find(ID) queries without a primary key defined" 
                    unless defined $primary_key;

                my ($sql, @values) = $sql_abstract->select( 
                                        $from, 
                                        $select, 
                                        { $primary_key => [$value, @rest] });
                return $class->find_by_sql($sql.$tail, @values);
            }
            # else, it a user-defined SQL condition
            else {
                my ($sql, @values) = $sql_abstract->select($from, $select, $value);
                $class->find_by_sql($sql.$tail, @values);
            }
        }
    }
    else {
       $class->find_by_sql( $sql_abstract->select( $from, $select ).$tail);
    }
}

# The generic SQL finder, takes a SQL query and map rows returned
# to objects of the class
sub find_by_sql {
    my ( $class, $sql, @values ) = @_;
    my @objects;

    # if cached, try to returned a cached value
    if (defined $class->cache) {
        my $cache_key = md5_base64($sql . (@values ? join(',', @values) : ''));
        my $value = $class->cache->get($cache_key);
        @objects = @$value if defined $value;
    }

    # no cache found, perform the query
    unless (@objects) {
        my $dbh = $class->dbh;
        my $sth = $dbh->prepare($sql);
        $sth->execute(@values) 
            or confess "Unable to execute query $sql : " . 
               $DBI::err . ' : ' . $DBI::errstr;
        my $rows = $sth->fetchall_arrayref( {} );

        # if any rows, let's process them
        if (@$rows) {
            # we have to find out which fields are real attributes
            my @attrs = Coat::Persistent::Meta->linearized_attributes( $class );
            my $lc = new List::Compare(\@attrs, [keys %{ $rows->[0] }]);
            my @given_attr   = $lc->get_intersection;
            my @virtual_attr = $lc->get_symdiff;

            # create the object with attributes, and set virtual ones
            foreach my $r (@$rows) {

                my %attributes = map { ($_ => $r->{$_}) } @given_attr;

                my $obj = $class->new(%attributes);
                $obj->init_on_find();
                foreach my $field (@virtual_attr) {
                    $obj->{$field} = $r->{$field};
                }

                $obj->{_db_state} = CP_ENTRY_EXISTS;
                push @objects, $obj;
            }
        }
        
        # save to the cache if needed
        if (defined $class->cache) {
            my $cache_key = md5_base64($sql . (@values ? join(',', @values) : ''));
            unless ($class->cache->set($cache_key, \@objects)) {
                warn "Unable to write to cache for key : $cache_key ".
                     "; maybe upgrade the cache_size : $!";
            }
        }
    }

    return wantarray
      ? @objects
      : $objects[0];
}


sub init_on_find {
}

sub BUILD {
    my ($self) = @_;
    $self->{_db_state} = CP_ENTRY_NEW;
}

sub validate {
    my ($self, @args) = @_;
    my $class = ref($self);
    my $table_name  = Coat::Persistent::Meta->table_name($class);
    
    foreach my $attr (Coat::Persistent::Meta->linearized_attributes($class) ) {
        
        # checking for unique attributes on inserting (new objects)
        if ($class->has_unique_constraint($attr)) {
            # look for other instances that already have that attribute
            my @items = $class->find(["$attr = ?", $self->$attr]);
            confess "Value ".$self->$attr." violates unique constraint "
                  . "for attribute $attr (class $class)"
                if @items;
        }
    }
}

sub delete {
    my ($self, $id) = @_;
    my $class  = ref $self || $self;
    my $dbh    = $class->dbh;
    my $table_name  = Coat::Persistent::Meta->table_name($class);
    my $primary_key = Coat::Persistent::Meta->primary_key($class);

    # TODO : we should provide a delete_by_$attr method for each attribute
    # and a also delete('condition SQL') support.
    confess "Cannot delete an entry without a primary_key defined" 
        unless defined $primary_key;

    confess "Cannot delete without an id" 
        if (!ref $self && !defined $id);
    
    confess "Cannot delete without a mapping defined for class " . ref $self
      unless defined $dbh;

    # if the argument given is an object, fetch its id
    $id = $self->$primary_key if ref($self);

    # at this, point, we must have an id
    confess "Cannot delete without a defined id" 
        unless defined $id;

    # delete the stuff
    $dbh->do("delete from ".$table_name." where $primary_key = $id");
}

# create is an alias for new + save, it can hande simple 
# and multiple creation.
# Class->create( foo => 'x', bar => 'y'); # simple creation
# Class->create([ { foo => 'x' }, {...}, ... ]); # multiple creation
sub create {
    # if only two args, we should have an ARRAY containing HASH

    if (@_ == 2) {
        my ($class, $values) = @_;
        confess "create received only two args but no ARRAY" 
            unless ref($values) eq 'ARRAY';
        $class->create(%$_) for @$values;
    }
    else {
        my ($class, %values) = @_;
        my $obj = $class->new(%values);
        $obj->save;
        $obj;
    }
}

# This will return the value as to be stored in the underlying database
# Most of the time it's just the value of the atrtribute, but it can 
# be different if a 'store_as' type is defined.
sub get_storage_value_for {
    my ($self, $attr_name) = @_;
    my $class = ref $self;

    my $attr = Coat::Meta->attribute($class, $attr_name);

    if ($attr->{store_as}) {
        my $storing_type = Coat::Types::find_type_constraint($attr->{store_as});
        return $storing_type->coerce($self->$attr_name);
    }
    else {
        return $self->$attr_name;
    }
}

# serialize the instance and save it with the mapper defined
sub save {
    my ($self, $conditions) = @_;
    my $class  = ref $self;
    my $dbh    = $class->dbh;
    my $table_name  = Coat::Persistent::Meta->table_name($class);
    my $primary_key = Coat::Persistent::Meta->primary_key($class);
    #warn "save\n\ttable_name: $table_name\n\tprimary_key: $primary_key\n";

    confess "Cannot save without a mapping defined for class " . ref $self
      unless defined $dbh;

    # make sure the object is sane
    $self->validate();

    # all the attributes of the class
    my @fields = Coat::Persistent::Meta->linearized_attributes( ref $self );

    # a hash containing attr/value pairs for the current object
    my %values = map { $_ => $self->get_storage_value_for($_) } @fields;
#    foreach my $k (keys %values) {
#        delete $values{$k} if not defined $values{$k};
#    }

    # if not a new object, we have to update
    if ( $self->_db_state == CP_ENTRY_EXISTS ) {

        # In order to update and entry, we need either a primary key or a sql
        # condition
        confess "cannot update without a primary key or a SQL condition"
            if (not defined $primary_key) and (not defined $conditions);

        # generate the SQL
        my ($sql, @values);
        if (defined $primary_key) {
            ($sql, @values) = $sql_abstract->update(
                $table_name, \%values, { $primary_key => $self->$primary_key});
        } 
        else { 
            ($sql, @values) = $sql_abstract->update(
                $table_name, \%values, $conditions);
        }
        # execute the query
        my $sth = $dbh->prepare($sql);
        $sth->execute( @values )
          or confess "Unable to execute query \"$sql\" : $DBI::errstr";
    }

    # new object, insert
    else {
        my ($sql, @values);
            
        confess "Primary key \"$primary_key\" has been set on a newborn object of class ".ref($self) 
            if (defined $primary_key && $self->$primary_key);

        if (defined $primary_key && has_internal_sequence_engine()) {
            # get our ID from the sequence
            $self->$primary_key( $self->_next_id );
    
            # generate the SQL
            ($sql, @values) = $sql_abstract->insert(
                $table_name, { %values, $primary_key => $self->$primary_key });
        }
        else {
            map { delete $values{$_} unless defined $values{$_} } keys %values;
            #warn "values: ".join(", ", keys(%values));
            ($sql, @values) = $sql_abstract->insert($table_name, \%values);
        }
        
        # execute the query
        #warn "sql: $sql ".join(', ', @values);
        my $sth = $dbh->prepare($sql);
        $sth->execute( @values )
          or confess "Unable to execute query \"$sql\" : $DBI::errstr";

        # Retrieve the primary key's value
        $self->$primary_key($class->get_last_insert_id($sth))
            if (defined $primary_key && !has_internal_sequence_engine());

        $self->{_db_state} = CP_ENTRY_EXISTS;
    }

    # if subobjects defined, save them
    if ( $self->{_subobjects} ) {
        foreach my $obj ( @{ $self->{_subobjects} } ) {
            $obj->save;
        }
        delete $self->{_subobjects};
    }

    return $self->$primary_key if defined $primary_key;
    return 'saved';
}


##############################################################################
# Private methods

# return the last insert id for any DBD supported
# raise an exception if the DBD is not supported
sub get_last_insert_id {
    my ($class, $sth) = @_;
    my $dbh = $class->dbh;
    my $driver = $class->driver;

    if ($driver eq 'mysql') {
        return $sth->{mysql_insertid} || $sth->{insertid};
    }
    elsif ($driver eq 'sqlite') {
        return $dbh->func('last_insert_rowid');
    }
    else {
        confess "DB driver '$driver' is not supported for last_insert_id";
    }
}

# instance method & stuff
sub _bind_code_to_symbol {
    my ( $code, $symbol ) = @_;

    {
        no strict 'refs';
        no warnings 'redefine', 'prototype';
        *$symbol = $code;
    }
}

sub _to_class {
    join '::', map { ucfirst $_ } split '_', $_[0];
}

# Takes a classname and translates it into a database table name.
# Ex: Class::Foo -> class_foo
sub _to_sql {
    my $table = ( ref $_[0] ) ? lc ref $_[0] : lc $_[0];
    $table =~ s/::/_/g;
    return $table;
}

sub _lock_write {
    my ($self) = @_;
    my $class = ref $self;
    return 1 if $class->driver ne 'mysql';

    my $dbh   = $class->dbh;
    my $table = Coat::Persistent::Meta->table_name($class);
    $dbh->do("LOCK TABLE $table WRITE")
      or confess "Unable to lock table $table";
}

sub _unlock {
    my ($self) = @_;
    my $class = ref $self;
    return 1 if $class->driver ne 'mysql';

    my $dbh = $class->dbh;
    $dbh->do("UNLOCK TABLES")
      or confess "Unable to lock tables";
}

sub _next_id {
    my ($self) = @_;
    my $class = ref $self;
    
    my $table = Coat::Persistent::Meta->table_name($class);
    my $dbh   = $class->dbh;

    my $sequence = new DBIx::Sequence({ dbh => $dbh });
    my $id = $sequence->Next($table);
    return $id;
}

# Returns a constant describing if the object exists or not
# already in the underlying DB
sub _db_state {
    my ($self) = @_;
    return $self->{_db_state} ||= CP_ENTRY_NEW;
}

# DBIx::Sequence needs two tables in the schema,
# this private function create them if needed.
sub _create_dbix_sequence_tables($) {
    my ($dbh) = @_;

    # dbix_sequence_state exists ?
    unless (_table_exists($dbh, 'dbix_sequence_state')) {
        # nope, create!
        $dbh->do("CREATE TABLE dbix_sequence_state (dataset varchar(50), state_id int(11))")
            or confess "Unable to create table dbix_sequence_state $DBI::errstr";
    }

    # dbix_sequence_release exists ?
    unless (_table_exists($dbh, 'dbix_sequence_release')) {
        # nope, create!
        $dbh->do("CREATE TABLE dbix_sequence_release (dataset varchar(50), released_id int(11))")
            or confess "Unable to create table dbix_sequence_release $DBI::errstr";
    }
}

# This is the best way I found to check if a table exists, with a portable SQL
# If you have better, tell me!
sub _table_exists($$) {
    my ($dbh, $table) = @_;
    my $sth = $dbh->prepare("select count(*) from $table");
    return 0 unless defined $sth;
    $sth->execute or return 0;
    my $nb_rows = $sth->fetchrow_hashref;
    return defined $nb_rows;
}

1;
__END__

=pod

=head1 NAME

Coat::Persistent -- Simple Object-Relational mapping for Coat objects

=head1 DESCRIPTION

Coat::Persistent is an object to relational-databases mapper, it allows you to
build instances of Coat objects and save them into a database transparently.

You basically define a mapping rule, either global or per-class and play with
your Coat objects without bothering with SQL for simple cases (selecting,
inserting, updating). 

Coat::Peristent lets you use SQL if you want to, considering SQL is the best
language when dealing with compelx queries.

=head1 WHY THIS MODULE ?

There are already very good ORMs for Perl available in the CPAN so why did this
module get added?

Basically for one reason: I wanted a very simple way to build persistent
objects for Coat and wanted something near the smart design of Rails'ORM
(ActiveRecord). Moreover I wanted my ORM to let me send SQL requests if I
wanted to (so I can do basic actions without SQL and complex queries with SQL).

This module is the result of my experiments of mixing DBI and Coat together,
although it is a developer release, it works pretty well and fit my needs.

This module is expected to change in the future (don't consider the API to be
stable at this time), and to grow (hopefully).

The underlying target of this module is to port the whole ActiveRecord::Base
API to Perl. If you find the challenge and the idea interesting, feel free to 
contact me for giving a hand. 

This is still a development version and should not be used in production
environment. 

=head1 DATA BACKEND

The concept behing this module is the same behind the ORM of Rails : there are
conventions that tell how to translate a model meta-information into a SQL
one :

The conventions implemented in Coat::Persistent are the following:

=over 4

=item The primary key of the tables mapped should be named 'id'.

=item Your table names must be named like the package they map, with the following
rules applied : lower case, replace "::" by "_". For instance a class Foo::Bar
should be mapped to a table named "foo_bar".

=item All foreign keys must be named "<table>_id" where table is the name if the
class mapped formated like said above.

=back

You can overide those conventions at import time:

    package My::Model;
    use Coat;
    use Coat::Persistent 
            table_name  => 'mymodel', # default would be 'my_model'
            primary_key => 'mid';     # default would be 'id'

=head2 ABOUT PRIMARY KEYS

Even if your table does not have a primary key, you can still use a
Coat::Persistent model over it. You just have to tell Coat::Persistent that
this table/model doesn't have a primary key :

   use Coat::Persistent primary_key => undef;

Note that instances of such a model cannot be saved like regular ones: there's
no primary key, so it's impossible to build UPDATE SQL queries properly. That's
why you'll have to give a condition whenver you call save().

For the same reason, it's impossible to use find() with numeric values (whi are
assumed to be primary key values).

Example :
    package Model;
    ...
    use Coat::Persistent primary_key => undef;
    ...

    package  main;

    my $obj = Model->find(43); # FAIL : there's no primary key known for Model
    my $obj = Model->find_by_some_attribute(25); # OK

    $obj->save(); # FAIL : the SQL query cannot be built without a primary key
                  # defined

    $obj->save({some_attribute => 25}); # OK

Note that it's not recommended to use tables whithout primary keys, the support
is only provided to support existing/border-line database schemas we can find
in real-world.

Use that feature with caution!

=head1 CONFIGURATION

You have two options for setting a database handle to your class. Either you
already have a dbh an you set it to your class, or you don't and you let
Coat::Persistent initialize it.

If you already have a database handle, use:

    # $driver is the driver name of the database handle (mysql, sqlite, ...)
    # $dbh is the database handle previously inititalized
    Coat::Persistent->set_dbh( $driver => $dbh);

Otherwise, use the DBI mapping explained below.

head2 ALREADY EXISTING DATABASE HANDLE

You may want to tell Coat::Persistent to use a $dbh you already have in hands,
then you can use the set_dbh() method.

=over 4

=item B<set_dbh($driver => $dbh)>

Set the given database handle for the calling class (set it by default if class
is Coat::Persistent).

=back

=head2 DBI MAPPING

You have to tell Coat::Persistent how to map a class to a DBI driver. You can
either choose to define a default mapper (in most of the cases this is what
you want) or define a mapper for a specific class.

In order for your mapping to be possible, the driver you use must be known by
Coat::Persistent, you can modify its driver mapping matrix if needed.

=over 4

=item B<drivers( )>

Return a hashref representing all the drivers mapped.

  MyClass->drivers;

=item B<get_driver( $name )>

Return the Perl module of the driver defined for the given driver name.
  
  MyClass->get_driver( 'mysql' );

=item B<add_driver( $name, $module )>

Add or replace a driver mapping rule. 

  MyClass->add_driver( sqlite => 'dbi:SQLite' );

=back

Then, you can use your driver in mapping rules. Basically, the mapping will
generate a DBI-E<gt>connect() call.

=over 4 

=item B<Coat::Persistent-E<gt>map_to_dbi $driver, @options >

This will set the default mapper. Every class that hasn't a specific mapper set
will use this one.

=item B<__PACKAGE__-E<gt>map_to_dbi $driver, @options >

This will set a mapper for the current class.

=back

Supported values for B<$driver> are the following :

=over 4

=item I<csv> : this will use DBI's "DBD:CSV" driver to map your instances to a CSV
file. B<@options> must contains a string as its first element being like the
following: "f_dir=<DIRECTORY>" where DIRECTORY is the directory where to store
de CSV files.

Example:

    packahe Foo;
    use Coat::Persistent;
    __PACKAGE__->map_to_dbi('csv', 'f_dir=./t/csv-directory');

=item I<mysql> : this will use DBI's "dbi:mysql" driver to map your instances
to a MySQL database. B<@options> must be a list that contains repectively: the
database name, the database user, the database password.

Example:

    package Foo;
    use Coat::Persistent;
    __PACKAGE__->map_to_dbi('mysql' => 'dbname', 'dbuser', 'dbpass' );

=back

=head2 MYSQL AUTO-INCREMENT FEATURE

When using MySQL, you can choose either to let Coat::Persistent set itself 
primary key values for new entries, or use MySQL auto_increment mechanism.

This is done by calling Coat::Persistent->disable_internal_sequence_engine();
before any call to map_to_dbi() or set_dbh().

Currently, this is only tested to work with MySQL, patches for supporting 
other database engines are welcome.

Make sure you disable the internal sequence engine before initializing the $dbh,
otherwise the two tables needed by DBIx::Sequence will be created in your DB 
(dbix_sequence_release and dbix_sequence_state).

A typical use of a MySQL database with auto_increment primary keys woudl like
the following:

    # $dbh is an hanlde to a MySQL DB
    Coat::Persistent->disable_internal_sequence_engine();
    Coat::Persistent->set_dbh(mysql => $dbh);

=head2 CACHING

Since version 0.0_0.2, Coat::Persistent provides a simple way to cache the
results of underlying SQL requests. By default, no cache is performed.

You can either choose to enable the caching system for all the classes (global
cache) or for a specific class. You could also define different cache
configurations for each class.

When the cache is enabled, every SQL query generated by Coat::Persistent is
first looked through the cache collection. If the query is found, its cached
result is returned; if not, the query is executed with the appropriate DBI
mapper and the result is cached.

The backend used by Coat::Persistent for caching is L<Cache::FastMmap> which
is able to expire the data on his own. Coat::Persistent lets you access the
Cache::FastMmap object through a static accessor :

=over 4

=item B<Coat::Persistent-E<gt>cache> : return the default cache object

=item B<__PACKAGE__-E<gt>cache> : return the cache object for the class __PACKAGE__

=back

To set a global cache system, use the static method B<enable_cache>. This
method receives a hash table with options to pass to the Cache::FastMmap
constructor.

Example :

    Coat::Persistent->enable_cache(
        expire_time => '1h',
        cache_size  => '50m',
        share_file  => '/var/cache/myapp.cache',
    );

It's possible to disable the cache system with the static method
B<disable_cache>.

See L<Cache::FastMmap> for details about available constructor's options.

=head1 METHODS

=head2 CLASS CONFIGURATION

The following pragma are provided to configure the mapping that will be 
done between a table and the class.

=over 4

=item B<has_p $name =E<gt> %options>

Coat::Persistent classes have the keyword B<has_p> to define persistent
attributes. Attributes declared with B<has_p> are valid Coat attributes and
take the same options as Coat's B<has> method. (Refer to L<Coat> for details).

All attributes declared with B<has_p> must exist in the mapped data backend
(they are a column of the table mapped to the class).

=item B<has_one $class>

Tells that current class owns a subobject of the class $class. This will allow
you to set and get a subobject transparently.

The backend must have a foreign key to the table of $class.

Example:

    package Foo;
    use Coat::Persistent;

    has_one 'Bar';

    package Bar;
    use Coat::Persistent;

    my $foo = new Foo;
    $foo->bar(new Bar);

=item B<has_many $class>

This is the same as has_one but says that many items are bound to one
instance of the current class.
The backend of class $class must provide a foreign key to the current class.

=back

=head2 CLASS METHODS

The following methods are inherited by Coat::Persistent classes, they provide
features for accessing and touching the database below the abstraction layer.
Those methods must be called in class-context.

=over 4 

=item I<Find by id>: This can either be a specific id or a list of ids (1, 5,
6)

=item I<Find in scalar context>: This will return the first record matched by
the options used. These options can either be specific conditions or merely an
order. If no record can be matched, undef is returned.

=item I<Find in list context>: This will return all the records matched by the
options used. If no records are found, an empty array is returned.

=back

The following options are supported :

=over 4

=item B<select>: By default, this is * as in SELECT * FROM, but can be
changed.

=item B<from>: By default, this is the table name of the class, but can be changed
to an alternate table name (or even the name of a database view). 

=item B<order>: An SQL fragment like "created_at DESC, name".

=item B<group>: An attribute name by which the result should be grouped. 
Uses the GROUP BY SQL-clause.

=item B<limit>: An integer determining the limit on the number of rows that should
be returned.

=back

Examples without options:

    my $obj = Class->find(23);
    my @list = Class->find(1, 23, 34, 54);
    my $obj = Class->find("field = 'value'");
    my $obj = Class->find(["field = ?", $value]);

Example with options:

    my @list = Class->find($condition, { order => 'field1 desc' })

=back

=item B<find_by_sql($sql, @bind_values>

Executes a custom sql query against your database and returns all the results
if in list context, only the first one if in scalar context.

If you call a complicated SQL query which spans multiple tables the columns
specified by the SELECT that aren't real attributes of your model will be
provided in the hashref of the object, but you won't have accessors.

The sql parameter is a full sql query as a string. It will be called as is,
there will be no database agnostic conversions performed. This should be a
last resort because using, for example, MySQL specific terms will lock you to
using that particular database engine or require you to change your call if
you switch engines.

Example:

    my $obj = Class->find_by_sql("select * from class where $cond");
    my @obj = Class->find_by_sql("select * from class where col = ?", 34);

=item B<create>

Creates an object (or multiple objects) and saves it to the database. 

The attributes parameter can be either be a hash or an array of hash-refs. These
hashes describe the attributes on the objects that are to be created.

Examples

  # Create a single new object
  User->create(first_name => 'Jamie')
  
  # Create an Array of new objects
  User->create([{ first_name => 'Jamie'}, { first_name => 'Jeremy' }])


=back

=head2 INSTANCE METHODS

The following methods are provided by objects created from the class.
Those methods must be called in instance-context.

=over 4 

=item B<save>

If no record exists, creates a new record with values matching those of the
object attributes.
If a record does exist, updates the record with values matching those
of the object attributes.

Returns the id of the object saved. 

=back

=head1 SEE ALSO

See L<Coat> for all the meta-class documentation. See L<Cache::FastMmap> for
details about the cache objects provided.

=head1 AUTHOR

This module was written by Alexis Sukrieh E<lt>sukria@cpan.orgE<gt>.
Quite everything implemented in this module was inspired from
ActiveRecord::Base's API (from Ruby on Rails).

Parts of the documentation are also taken from ActiveRecord::Base when
appropriate.

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Alexis Sukrieh.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
