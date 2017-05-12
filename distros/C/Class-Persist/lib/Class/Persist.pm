=head1 NAME

Class::Persist - Persistency framework for objects

=head1 SYNOPSIS

  package My::Person;
  use base qw( Class::Persist );
  __PACKAGE__->dbh( $dbh );
  __PACKAGE__->simple_db_spec(
    first_name => 'CHAR(30)',
    last_name  => 'CHAR(30)',
    address => "My::Address",  # has_a relationship
    phones => [ "My::Phone" ], # has_many relationship
  );

  my $person = My::Person->new( first_name => "Dave" );
  $person->addesss( My::Address->new );
  $person->store;
  

=head1 DESCRIPTION

Provides the framework to persist the objects in a DB in a Class::DBI style

=head1 INHERITANCE

 Class::Persist::Base

=head1 METHODS

=cut

package Class::Persist;
use strict;
use warnings;
use Class::ISA;
use DateTime;
use Scalar::Util qw(blessed);
use Data::Structure::Util;

use DBI;
use Class::Persist::Proxy;
use Class::Persist::Proxy::Collection;

use base qw(Class::Persist::Base Class::Data::Inheritable);

our $VERSION = '0.02';

our $ID_FIELD = "OI";

our $SQL; # sql cache
our $SCHEME = {}; # mapping class <=> db

# Maximum number of rows to return.
our $LIMIT = 10_000;

Class::Persist->mk_classdata('dbh');

__PACKAGE__->db_fields( $Class::Persist::ID_FIELD, qw( creation_date timestamp owner ) );
__PACKAGE__->mk_accessors(qw( _from_db creation_date timestamp ));
__PACKAGE__->db_fields_spec(
  $ID_FIELD.' CHAR(36) PRIMARY KEY',
  'timestamp TIMESTAMP',
  'creation_date CHAR(30) NOT NULL',
  'owner CHAR(36)',
);

require Class::Persist::Tracker;
require Class::Persist::Deleted;

exception Class::Persist::Error::DB            extends => 'Class::Persist::Error';
exception Class::Persist::Error::DB::Connection extends => 'Class::Persist::Error::DB';
exception Class::Persist::Error::DB::Request   extends => 'Class::Persist::Error::DB';
exception Class::Persist::Error::DB::NotFound  extends => 'Class::Persist::Error::DB';
exception Class::Persist::Error::DB::Duplicate extends => 'Class::Persist::Error::DB';
exception Class::Persist::Error::DB::UTF8 extends => 'Class::Persist::Error::DB';

=head2 creation_date

A string representing when this object was originally created.

=cut

sub init {
  my $self = shift;
  $self->SUPER::init(@_) or return;

  unless ($self->creation_date) {
    my $now = DateTime->now;
    my $string = $now->ymd('-') . ' ' . $now->hms(':');
    $self->creation_date( $string );
  }

  return $self->_setup_relationships;
}

sub _populate {
  my $self = shift;
  $self->SUPER::_populate(@_);
  return $self->_setup_relationships;
}

# put placeholders in the has_many, etc, slots.
# called after init and populate.
sub _setup_relationships {
  my $self = shift;

  my $methods = $self->might_have_all;
  foreach my $method (keys %$methods) {
    my $proxy = Class::Persist::Proxy->new();
    $proxy->class( $methods->{$method} );
    $proxy->owner( $self );
    $self->set( $method => $proxy );
  }
  $methods = $self->has_many_all;
  foreach my $method (keys %$methods) {
    my $proxy = Class::Persist::Proxy::Collection->new();
    $proxy->class( $methods->{$method} );
    $proxy->owner( $self );
    $self->set( $method => $proxy );
  }
  $self->inflate();

  return $self;
}


=head2 load( $id )

Loads an object from the database. Can be used in three different ways -

=over 4

=item Class::Persist->load( $id )

loads an object based on its oid

=item Class::Persist->load( key => $value )

get the first match of single key test

  Person->load( name => "Dave" );

=item $obj->load()

loads an object based on its current state, eg -

  my $person = Person->new;
  $person->name('Harry');
  $person->load or die "There's noone called Harry";
  print $person->email;

=back

=cut

sub load {
  my $class = shift;
  # If it is an instance call, replace by loaded object
  if (ref $class) {
    my $real_class = ref $class;
    my $self = $real_class->_load( $ID_FIELD => $class->oid ) or return;
    $class->same_than($self) or return;
    return $class->_duplicate_from($self);
  }
  # Class call

  # load by owner for might_have relationships
  if (blessed( $_[0] )) {
    my $self = $class->_load( owner => $_[0]->oid ) or return;
    $self->owner($_[0]);
    return $self;
  }

  $class->_load($ID_FIELD, @_);
}


sub _load {
  my $class   = shift;

  my $id      = pop or return $class->record('Class::Persist::Error::InvalidParameters', "Need an id to load object", 1);
  my $idField = pop or return $class->record('Class::Persist::Error::InvalidParameters', "Need an id to load object", 1);

  my (@got) = $class->sql("$idField=?", $id);
  if (@got != 1) {
    return $class->record('Class::Persist::Error::DB::NotFound', "No object $id loaded for $class");
  }
  $got[0];
}

=head2 revert()

revert an object back to its state in the database.

TODO - make recursive

=cut

sub revert {
  my $self = shift;
  Class::Persist::Error->throw( text => "Can only revert objects" )
    unless ref($self);

  Class::Persist::Error::DB->throw( text => "Object is not from the database" )
    unless $self->_from_db;

  my $reverted = ref($self)->_load( $ID_FIELD => $self->oid )
    or Class::Persist::Error::DB->throw( text => "No object with that oid in DB");

  return $self->_duplicate_from($reverted);
}


=head2 store()

Store the object in DB and all objects within, whether it is a new object or an update

=cut

sub store {
  my $self = shift;
  $self->check_store(@_) or return; # check_store records errors;

  $self->store_might_have() or return;
  $self->store_has_many() or return;
  $self->deflate();

  if ($self->_from_db) {
    $self->db_update() or return;
  }
  else {
    $self->db_insert() or return;
    $self->track();
  }
  $self->_from_db(1);

  $self->inflate();
}


=head2 delete()

Deletes the object and returns true if successful.
It will delete recursively all objects within.

=cut

sub delete {
  my $self = shift;
  return $self->record('Class::Persist::Error', "Can't delete a non stored object", 1) unless $self->_from_db;

  my $methods = $self->might_have_all;
  foreach my $method (keys %$methods) {
    my $obj = $self->get( $method ) or next;
    $obj->delete() or next;
    Class::Persist::Proxy->proxy($obj);
  }
  $methods = $self->has_many_all;
  foreach my $method (keys %$methods) {
    my $obj = $self->get( $method ) or next;
    $obj->delete();
  }
  $methods = $self->has_a_all;
  foreach my $method (keys %$methods) {
    my $obj = $self->get( $method ) or next;
    $obj->delete();
    Class::Persist::Proxy->proxy($obj);
  }

  $self->deleteThis();
}


=head2 deleteThis()

Deletes the object and returns true if successful.
Does not delete recursively any objects within.


=cut

sub deleteThis {
  my $self  = shift;
  my $dbh   = $self->dbh;
  my $table = $self->db_table;

  my $sql   = "DELETE FROM $table WHERE $ID_FIELD=?";

  my $r = $dbh->prepare_cached($sql) or Class::Persist::Error::DB::Request->throw(text => "Could not prepare $sql - $DBI::errstr");
  $r->execute($self->oid)            or Class::Persist::Error::DB::Request->throw(text => "Could not execute $sql - $DBI::errstr");
  $r->finish;

  $self->store_deleted();
  $self->_from_db(0);
}

=head2 owner( $obj )

=cut

sub owner {
  my $self = shift;
  if (my ($owner) = @_) {
    if (blessed($owner) and ! $owner->isa('Class::Persist::Proxy')) {
      my $proxy = Class::Persist::Proxy->new();
      $proxy->class( ref $owner );
      $proxy->real_id( $owner->oid );
      $owner = $proxy;
    }
    return $self->set('owner', $owner);
  }
  return $self->get('owner');
}

=head2 oids_for_owner( $owner )

=cut

sub oids_for_owner {
  my $self  = shift;
  my $owner = shift or Class::Persist::Error::InvalidParameters->throw(text => "A owner should be passed");

  my $dbh   = $self->dbh;
  my $table = $self->db_table;
  my $sql   = "SELECT $ID_FIELD FROM $table WHERE owner=? LIMIT $LIMIT";

  my $r     = $dbh->prepare_cached($sql) or Class::Persist::Error::DB::Request->throw(text => "Could not prepare $sql - $DBI::errstr");
  $r->execute($owner->oid) or Class::Persist::Error::DB::Request->throw(text => "Could not execute $sql - $DBI::errstr");
  my $rows = $r->fetchall_arrayref or return $self->record('Class::Persist::Error::DB::NotFound', "No object loaded");
  $r->finish();

  Class::Persist::Error::DB::Request->throw(text => "Limit reached in $sql") if (@$rows == $LIMIT);
  [ map $_->[0], @$rows ];
}

=head2 track()

Store the class and oid to make future retrieval easier

=cut

sub track {
  my $self = shift;
  Class::Persist::Tracker->new()->object( $self )->store(); # or die "can't track $self";
}


=head2 store_deleted()

Stores the object in the deleted object table.

=cut

sub store_deleted {
  Class::Persist::Deleted->new()->object( shift )->store();
}


=head2 store_might_have()

Stores all objects in a might-have relationship with this class.

=cut

sub store_might_have {
  my $self = shift;
  foreach my $key ( keys %{ $self->might_have_all } ) {
    my $obj = $self->get($key) or next;
    next if $obj->isa('Class::Persist::Proxy');
    $obj->isa('Class::Persist') or Class::Persist::Error->throw(text => "Object not a Class::Persist");
    $obj->owner( $self );
    $obj->store() or return;
    Class::Persist::Proxy->proxy($obj, $self);
  }
  $self;
}


=head2 store_has_many()

Stores all objects in a one-to-many relationship with this class.

=cut

sub store_has_many {
  my $self = shift;
  foreach my $key ( keys %{ $self->has_many_all } ) {
    my $obj = $self->get( $key ) or next;
    $obj->isa('Class::Persist::Proxy') or Class::Persist::Error->throw(text => "Object not a Class::Persist::Proxy");
    $obj->owner( $self );
    $obj->store() or return;
  }
  $self;
}

=head2 deflate()

Store the object, and replace an object with a Class::Persist::Proxy
pointing at it in the database.

=cut

sub deflate {
  my $self = shift;
  my $methods = $self->has_a_all;
  foreach my $method (keys %$methods) {
    my $obj = $self->get($method) or next;
    next unless ref($obj);
    $obj->store() or return;
    $self->set( $method => $obj->oid );
  }

  if (my $owner = $self->owner) {
    $self->owner( $owner->oid ) if ref($owner);
  }

  $self;
}


=head2 inflate()

Replace oids by a proxy

=cut

sub inflate {
  my $self = shift;
  my $methods = $self->has_a_all;
  foreach my $method (keys %$methods) {
    my $oid = $self->get($method) or next;
    next if ref($oid);
    my $proxy = Class::Persist::Proxy->new;
    $proxy->oid($oid);
    $proxy->class( $methods->{$method} );
    $proxy->real_id( $oid );
    $self->set( $method => $proxy );
  }

  if (my $owner = $self->owner) {
    unless (ref $owner) {
      my $proxy = Class::Persist::Proxy->new();
      $proxy->real_id( $owner );
      $self->owner( $proxy );
    }
  }

  $self;
}


=head2 check_store()

=cut

sub check_store {
  my $self = shift;
  $self->validate() or return $self->record('Class::Persist::Error::InvalidParameters', "validation of $self failed", 1);
  $self->unique()   or return $self->record('Class::Persist::Error::DB::Duplicate', "duplicate of $self found", 1);
  1;
}

=head2 clone()

Deep-clones the object - any child objects will also be cloned. All new objects
will have new oids.

=cut

sub clone {
  my $self = shift;

  # de-proxificate more than once, because loading might create more
  # proxies
  my $deproxificated = 1;
  while ($deproxificated) {
    $deproxificated = 0;
    foreach my $object (@{ Data::Structure::Util::get_blessed($self) }) {
      if ($object->isa('Class::Persist::Proxy')) {
        $object->load
          or die "Can't load $object with oid ".$object->real_id." : $@\n";
        $deproxificated++;
      }
    }
  }

  my $clone = $self->SUPER::clone(@_);

  foreach my $object (@{ Data::Structure::Util::get_blessed($clone) }) {
    if ($object->isa('Class::Persist')) {
      $object->_from_db(0);
    }
  }

  return $clone;
}

=head2 validate()

Returns true if the object is in a good, consistent state and can be stored.
Override this method if you want to make sure your objects are consistent
before storing.

=cut

sub validate { 1 }


=head2 unique()

Returns true if the current object is unique, ie there is no other row in
the database that has the same value as this object. The query that is
used to check for uniqueness is defined by the L<unique_params> method.

Only checked for unstored objects - objects that have come from the database
are presumed to be unique.

=cut

# _WHY_ are they presumed to be unique?

sub unique {
  my $self = shift;
  return 1 if $self->_from_db; # shortcut - no need to test if obj is from db
  my $dbh = $self->dbh;
  my @params = $self->unique_params;
  ! ($dbh->selectrow_array(shift @params, undef, @params))[0];
}



=head2 same_than( $obj )

Compares all the fields containing a scalar except oid

=cut

sub same_than {
  my $self  = shift;
  my $other = shift;
  foreach my $key ($self->db_fields) {
    next if ($key eq $ID_FIELD);
    next if ( !$self->get($key) and !$other->get($key) );
    next if ref($self->get($key));
    next if ($self->get($key) eq $other->get($key));
    return $self->record('Class::Persist::Error::InvalidParameters', "Parameter $key mismatch", 1);
  }
  1;
}


=head2 might_have( $method => $class )

=cut

sub might_have {
  my $self  = shift;
  my $class = ref($self) || $self;
  if (my $method = shift) {
    my $target = shift;
    $SCHEME->{$class}->{this}->{might_have}->{$method} = $target;
  }
  $SCHEME->{$class}->{this}->{might_have};
}


=head2 might_have_all()

=cut

sub might_have_all {
  my $self  = shift;
  my $class = ref($self) || $self;

  unless ( $SCHEME->{$class}->{all}->{might_have} ) {
    $SCHEME->{$class}->{all}->{might_have} = {};
    foreach my $isa ( reverse $class, Class::ISA::super_path($class) ) {
      exists $SCHEME->{$isa} or next;
      my $methods = $SCHEME->{$isa}->{this}->{might_have} or next;
      %{$SCHEME->{$class}->{all}->{might_have}} = (%{$SCHEME->{$class}->{all}->{might_have}}, %$methods);
    }
  }

  $SCHEME->{$class}->{all}->{might_have};
}


=head2 has_a( $method => $class )

Class method. Defines a has_a relationship with another class.

  Person::Body->has_a( head => "Person::Head" );
  my $nose = $body->head->nose;

Allows you to store references to other Class::Persist objects. They will
be serialised when stored in the database.

=cut

sub has_a {
  my $self  = shift;
  my $class = ref($self) || $self;
  if (my $method = shift) {
    my $target = shift;
    $SCHEME->{$class}->{this}->{has_a}->{$method} = $target;
  }
  $SCHEME->{$class}->{this}->{has_a};
}


=head2 has_a_all()

=cut

sub has_a_all {
  my $self  = shift;
  my $class = ref($self) || $self;

  unless ( $SCHEME->{$class}->{all}->{has_a} ) {
    $SCHEME->{$class}->{all}->{has_a} = {};
    foreach my $isa ( reverse $class, Class::ISA::super_path($class) ) {
      exists $SCHEME->{$isa} or next;
      my $methods = $SCHEME->{$isa}->{this}->{has_a} or next;
      %{$SCHEME->{$class}->{all}->{has_a}} = (%{$SCHEME->{$class}->{all}->{has_a}}, %$methods);
    }
  }

  $SCHEME->{$class}->{all}->{has_a};
}


=head2 has_many( $method => $class )

Class method. Defineds a one to many relationship with another class.

  Person::Body->has_many( arms => 'Person::Arm' );
  my $number_of_arms = $body->arms->count;

Allows you to manipulate a number of other Class::Persist objects that are
associated with this one. This method will return a
L<Class::Persist::Proxy::Container> that handles the child objects, it
provides push, pop, count, etc, methods to add and remove objects from the
list.

  my $left_arm = Person::Arm->new;
  $body->arms->push( $left_arm );

=cut

sub has_many {
  my $self  = shift;
  my $class = ref($self) || $self;
  if (my $method = shift) {
    my $target = shift;
    $SCHEME->{$class}->{this}->{has_many}->{$method} = $target;
  }
  $SCHEME->{$class}->{this}->{has_many};
}


=head2 has_many_all()

=cut

sub has_many_all {
  my $self  = shift;
  my $class = ref($self) || $self;

  unless ( $SCHEME->{$class}->{all}->{has_many} ) {
    $SCHEME->{$class}->{all}->{has_many} = {};
    foreach my $isa ( reverse $class, Class::ISA::super_path($class) ) {
      exists $SCHEME->{$isa} or next;
      my $methods = $SCHEME->{$isa}->{this}->{has_many} or next;
      %{$SCHEME->{$class}->{all}->{has_many}} = (%{$SCHEME->{$class}->{all}->{has_many}}, %$methods);
    }
  }

  $SCHEME->{$class}->{all}->{has_many};
}


=head2 unique_params()

SQL query and binding params used to check unicity of object in DB

=cut

sub unique_params {
  my $self = shift;
  my $table = $self->db_table;
  ("SELECT 1 FROM $table WHERE $ID_FIELD=?", $self->oid);
}


=head2 db_table( $table )

Get/set accessor for the DB table used to store this class.

=cut

sub db_table {
  my $self  = shift;
  my $class = ref($self) || $self;
  if (my $table = shift) {
    $SCHEME->{$class}->{table} = $table;
  }
  $SCHEME->{$class}->{table};
}


=head2 db_fields( @fields )

Get/set accessor for the DB fields used to store the attributes specific to
class (but not its parent(s)). Override this in your class to define the scalar
properties of your object that should be stored in columns of the database.

=cut

sub db_fields {
  my $self  = shift;
  my $class = ref($self) || $self;
  if (my @fields = @_) {
    $SCHEME->{$class}->{this}->{fields} = \@fields;
  }
  @{$SCHEME->{$class}->{this}->{fields} || []};
}


=head2 db_fields_all()

Get/set accessor for all the DB fields used to store this class.

=cut

sub db_fields_all {
  my $self  = shift;
  my $class = ref($self) || $self;
  if (my @fields = @_) {
    $SCHEME->{$class}->{all}->{fields} = \@fields;
  }

  unless ( $SCHEME->{$class}->{all}->{fields} ) {
    $SCHEME->{$class}->{all}->{fields} = [];
    foreach my $isa ( reverse $class, Class::ISA::super_path($class) ) {
      exists $SCHEME->{$isa} or next;
      if (my $fields = $SCHEME->{$isa}->{this}->{fields}) {
        push @{$SCHEME->{$class}->{all}->{fields}}, @$fields;
      }
      if (my $fields = $SCHEME->{$isa}->{this}->{has_a}) {
        push @{$SCHEME->{$class}->{all}->{fields}}, keys(%$fields);
      }
    }
  }

  my %unique = map { $_ => 1 } @{$SCHEME->{$class}->{all}->{fields}};
  @{$SCHEME->{$class}->{all}->{fields}} = sort(keys(%unique));
}

=head2 binary_fields( @fields )

=cut

sub binary_fields {
  my $self  = shift;
  my $class = ref($self) || $self;
  if (my @fields = @_) {
    $SCHEME->{$class}->{this}->{binary} = \@fields;
  }
  @{$SCHEME->{$class}->{this}->{binary}};
}


=head2 binary_fields_all()

=cut

sub binary_fields_all {
  my $self  = shift;
  my $class = ref($self) || $self;
  if (my @binary = @_) {
    $SCHEME->{$class}->{all}->{binary} = \@binary;
  }

  unless ( $SCHEME->{$class}->{all}->{binary} ) {
    $SCHEME->{$class}->{all}->{binary} = [];
    foreach my $isa ( reverse $class, Class::ISA::super_path($class) ) {
      exists $SCHEME->{$isa} or next;
      if (my $binary = $SCHEME->{$isa}->{this}->{binary}) {
        push @{$SCHEME->{$class}->{all}->{binary}}, @$binary;
      }
    }
  }

  my %unique = map { $_ => 1 } @{$SCHEME->{$class}->{all}->{binary}};
  @{$SCHEME->{$class}->{all}->{binary}} = sort(keys(%unique));
}

=head2 db_insert()

Insert the object in the DB as a new entry

=cut

sub db_insert {
  my $self = shift;

  my $dbh    = $self->dbh;
  my $sql    = $self->db_insert_sql;
  my @fields = $self->db_fields_all;

  my %binary = map { $_ => 1 } $self->binary_fields_all;
  my @values;
  for my $field (@fields) {
    my $value = $self->get($field);
    utf8::encode($value) unless ($binary{$field} or !defined($value));
    push @values, $value;
  }

  my $r = $dbh->prepare_cached($sql)
    or Class::Persist::Error::DB::Request->throw(
      text => "Could not prepare $sql - $DBI::errstr");

  $r->execute(@values)
    or Class::Persist::Error::DB::Request->throw(
      text => "Could not execute $sql - $DBI::errstr");

  $r->finish;
}


=head2 db_update()

Update the object in the DB

=cut

sub db_update {
  my $self = shift;

  my $dbh    = $self->dbh;
  my $sql    = $self->db_update_sql;
  my @fields = $self->db_fields_all;

  my %binary = map { $_ => 1 } $self->binary_fields_all;
  my @values;
  for my $field (@fields) {
    my $value = $self->get($field);
    utf8::encode($value) unless ($binary{$field} or !defined($value));
    push @values, $value;
  }

  my $r = $dbh->prepare_cached($sql) or Class::Persist::Error::DB::Request->throw(text => "Could not prepare $sql - $DBI::errstr");
  $r->execute(@values, $self->oid)   or Class::Persist::Error::DB::Request->throw(text => "Could not execute $sql - $DBI::errstr");
  $r->finish;
}


=head2 db_insert_sql()

Generate SQL for an insert statement for this object

=cut

sub db_insert_sql {
  my $self = shift;

  my $table = $self->db_table;
  my $sql = $SQL->{$table}->{insert};
  unless ($sql) {
    my @fields  = $self->db_fields_all;
    my $columns = join(',', @fields);
    my $holders = join(',', ('?') x scalar(@fields));
    $sql = "INSERT INTO $table ($columns) VALUES ($holders)";
    $SQL->{$table}->{insert} = $sql;
  }
  $sql;
}


=head2 db_update_sql()

Generate SQL for an update statement for this object

=cut

sub db_update_sql {
  my $self = shift;

  my $table = $self->db_table;
  my $sql = $SQL->{$table}->{update};
  unless ($sql) {
    my @fields = $self->db_fields_all;
    my $set = join(',', map { "$_=?" } @fields);
    $sql = "UPDATE $table SET $set WHERE $ID_FIELD=?";
    $SQL->{$table}->{update} = $sql;
  }
  $sql;
}


=head2 db_table_sql()

=cut

sub db_table_sql {
  my $self = shift;
  "(". join(', ', $self->db_fields_spec_all) .")";
}

=head2 db_fields_spec()

SQL to specificy the database columns needed to store the attributes of this
class - all parent class(es) columns are aggregated and used to build an SQL
create table statement. Override this to specify the columns used by your class,
if you want Class::Persist to be able to create your table for you.
Remember to call the superclass db_fields_spec as well, though.

  sub db_fields_spec(
    shift->SUPER::db_fields_spec,
    'Colour VARCHAR(63)',
    'Mass VARCHAR(63)',
  );


=cut

sub db_fields_spec {
  my $self = shift;
  my $class = ref($self) || $self;
  if (my @spec = @_) {
    $SCHEME->{$class}->{this}->{db_fields_spec} = \@spec;
    return $self;
  }
  return @{ $SCHEME->{$class}->{this}->{db_fields_spec} || [] };
}

sub db_fields_spec_all {
  my $self  = shift;
  my $class = ref($self) || $self;

  unless ( $SCHEME->{$class}->{all}->{db_fields_spec} ) {
    my @list;
    foreach my $isa ( reverse $class, Class::ISA::super_path($class) ) {
      $isa->can('db_fields_spec') or next;
      push @list, $isa->db_fields_spec;
    }
    my %u = map { $_ => 1 } @list;
    @list = sort keys %u;
    $SCHEME->{$class}->{all}->{db_fields_spec} = \@list;
  }

  @{ $SCHEME->{$class}->{all}->{db_fields_spec} };
}

=head2 simple_db_spec

An alternative way of specifying the database spec, combining the field list,
has_a and has_many relationships and the database spec in one command.

  Person::Foot->simple_db_spec(
    digits => 'INT',
    name => 'CHAR(10)',
    leg => 'Person::Leg',
    hairs => [ 'Person::Leg::Hair' ],
  );

For each colnm as the keys of the passed hash, specify a simple DB field
with a DB type, a has_a relationship with a class name, and a has_many
relationship with a listref continain a single element - the class name.

This will also automatically create a name for the database table, if you
don't want to supply one yourself. The name will be based on the package name.

=cut

sub simple_db_spec {
  my $class = shift;
  my %spec = ref($_[0]) ? %{$_[0]} : @_;
  die "simple_db_spec is a class method" if ref($class);

  # make up a table name if needed
  unless ($class->db_table) {
    my $table = lc($class);
    $table =~ s/::/_/g;
    $class->db_table( $table );
  }


  # walk the spec, interpret minilanguage
  # class names are turned into has_a relationships,
  # listrefs become has_many relationships.
  my @simple;
  for my $col (keys %spec) {

    if (ref($spec{$col}) eq 'ARRAY') {
      $class->has_many( $col, @{ $spec{$col} } );
      delete $spec{$col};

    } elsif ($spec{$col} =~ /::/) {
      $spec{$col} =~ s/::$//;
      eval "use $spec{$col}"; die "Can't eval class $spec{$col} => $@\n" if $@;
      $class->has_a( $col => $spec{$col} );
      $spec{$col} = "CHAR(36)";

    } else {
      push @simple, $col;
    }
  }

  $class->db_fields(@simple);
  $class->db_fields_spec( map { "$_ $spec{$_}" } keys %spec );

}



=head2 drop_table()

Drop the table for this class.

=cut

sub drop_table {
  my $self  = shift;
  my $dbh   = $self->dbh;
  my $table = $self->db_table or die "No table name";
  # XXX can't portably IF EXISTS
  $dbh->do("DROP TABLE $table"); #  or warn "Could not execute - $DBI::errstr";
}


=head2 create_table

Create the table for this class.

=cut

sub create_table {
  my $self  = shift;
  my $dbh   = $self->dbh;
  my $table = $self->db_table     or die "No table name";
  my $sql   = $self->db_table_sql or die "No table sql for $table";

  $dbh->do("CREATE TABLE $table $sql") or die "Could not execute $sql - $DBI::errstr";
}

=head2 setup_DB_infrastructure

Class::Persist needs the existence of 2 tables in addition to the ones used
to store object data. This method will create the tables in the database for
this object.

=cut

sub setup_DB_infrastructure {
  Class::Persist::Tracker->create_table() and
      Class::Persist::Deleted->create_table();
}

=head2 destroy_DB_infrastructure

Class::Persist needs the existence of 2 tables in addition to the ones used
to store object data. This method will remove the tables from the database for
this object.

=cut

sub destroy_DB_infrastructure {
  Class::Persist::Tracker->drop_table() and
      Class::Persist::Deleted->drop_table()
}

=head2 get_all

Returns a list of all the objects in this classes table in the database.

=cut

sub get_all {
  my $class = shift;
  return $class->search();
}

=head2 search

Takes a hash of attribute=>value pairs. Values of undef become IS NULL tests.
Returns a list of objects in the database of this class which match these
criteria.

  my $pears = Fruit->search( shape => 'pear' );

The special parameter 'order_by' will not be used as part of the search, but
will order the results by that column.

  my $sorted_pears = Fruit->search( shape => 'pear', order_by => 'size' );

=cut

sub search {
  my $class = shift;
  my $param = ref($_[0]) ? $_[0] : { @_ };

  for (values(%$param)) {
    $_ = $_->oid if (blessed($_));
  }

  my $order_by = delete($param->{order_by});

  my $sql = "";
  if (keys(%$param)) {
    $sql = join( " AND ", map {
      defined($param->{$_}) ? "$_ = ?" : "$_ IS NULL"
    } keys(%$param) );
  } else {
    $sql = "1=1";
  }
  $sql .= ' ORDER BY '.$order_by if $order_by;

  return $class->sql( $sql, values(%$param) );
}


=head2 sql( sql, [placeholder values] )

Free-form search based on a SQL query. Returns a list of objects from the
database for each row of the passed SQL 'WHERE' clause. You can use placeholders
in this string, passing the values for the placeholders as the 2nd, etc, params

  Person->sql("name LIKE '%ob%' AND age > ? ORDER BY height", $min_age)

=cut

sub sql {
  my $class = shift;
  my $query = shift;

  my $dbh   = $class->dbh;
  my $table = $class->db_table;
  my @fields = $class->db_fields_all;

  # We have to go through this game of selecting all the fields explicitly
  # (and in a known order) rather than simply using fetchrow_arrayref because
  # DBD::Pg appears not to be case-preserving the column names.
  # Without doing this tests will fail on Pg when attributes are not all lower
  # case.
  my $sql   = "SELECT " . join (',', @fields) . " FROM $table";

  if ($query) {
    $sql .= " WHERE $query";
  }

  my $r = $dbh->prepare_cached($sql)
    or Class::Persist::Error::DB::Request->throw(
      text => "Could not prepare $sql - $DBI::errstr");

  my @placeholders = grep { defined($_) } @_;
  utf8::encode $_ foreach @placeholders;

  $r->execute( @placeholders )
    or Class::Persist::Error::DB::Request->throw(
      text => "Could not execute $sql - $DBI::errstr");

  my @return;

  my $limit = $LIMIT; # arbitrary limits. Bah.
  # Do this out here to avoid recreating hash each time.
  my %temp;
  while (my $row = $r->fetchrow_arrayref() and --$limit) {
    @temp{@fields} = @$row;
    # Do it this way round to avoid a bug in DBI, where DBI doesn't reset
    # the utf8 flag on the array it reuses for fetchrow_arrayref
    # We're now doing it here on copies of the data
    my %binary = map { $_ => 1 } $class->binary_fields_all;
    for (keys(%temp)) {
      next if $binary{$_};
      unless (utf8::decode($temp{$_})) {
        Class::Persist::Error::DB::UTF8->throw(
          text => "Non-utf8 data in column $_ returned by $sql");
      }
    }
    push(@return, $class->new->_populate(\%temp)->_from_db(1));
  }

  $r->finish();

  return @return;
}

=head2 advanced_search

when search() isn't good enough, and even sql() isn't good enough, you
want advanced_search. You pass a complete SQL statement that will return
a number of rows. It is assumed that the left-most column will contain
oids. These oids will be inflated from the database and returned in a
list.

As with the sql method, you can use placeholders and pass the values as
the remaining parameters.

  People->advanced_sql('
    SELECT artist.oid FROM artist,track
    WHERE track.artist_name = artist.name
    AND track.length > ?
    ORDER BY artist.name',
  100 );

This will be slower than sql - there will be another SQL query on the db
for every row returned. That's life. There is much scope here for
optimization - the simplest thing to do might be to return a list of
proxies instead..

Also consider that the SQL statement you're passing will be just thrown
at the database. You can call Object->advanced_sql('DROP DATABASE
people') and bad things will happen. This is, of course, almost equally
true for the sql method, but it's easier to break things with this one.

=cut

sub advanced_search {
  my $class = shift;
  my $sql = shift;

  my $dbh   = $class->dbh;

  my $r = $dbh->prepare_cached($sql)
    or Class::Persist::Error::DB::Request->throw(
      text => "Could not prepare $sql - $DBI::errstr");

  my @placeholders = grep { defined($_) } @_;
  utf8::encode $_ foreach @placeholders;

  $r->execute( @placeholders )
    or Class::Persist::Error::DB::Request->throw(
      text => "Could not execute $sql - $DBI::errstr");

  my @return;

  my $limit = $LIMIT; # arbitrary limits. Bah.
  # Do this out here to avoid recreating hash each time.
  my %row;
  while (my $row = $r->fetchrow_arrayref() and --$limit) {
    my $oid = $row->[0];
    push( @return, $class->load($oid) );
  }

  $r->finish();

  return @return;
}

1;
__END__

=head1 CAVEATS

The API isn't yet stabilised, so please keep an eye on the Changes file
where incompatible changes will be noted.

=head1 AUTHORS

=over

=item Nicholas Clark <nclark@fotango.com>

=item Pierre Denis   <pdenis@fotango.com>

=item Tom Insam      <tinsam@fotango.com>

=item Richard Clamp  <richardc@unixbeard.net>

=back

This module was influnced by James Duncan and Piers Cawley's Pixie object
persistence framework, and Class::DBI, by Michael Schwern and Tony Bowden 
(amongst many others), as well as suggestions from various people within 
Fotango.

=head1 COPYRIGHT

Copyright 2004 Fotango.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# Local Variables:
# mode: CPerl
# cperl-indent-level: 2
# indent-tabs-mode: nil
# End:
