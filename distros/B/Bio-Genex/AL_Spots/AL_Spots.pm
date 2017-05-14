##############################
#
# Bio::Genex::AL_Spots
#
# created on Mon Feb  5 21:23:56 2001 by /home/jasons/work/GeneX-Server/Genex/scripts/create_genex_class.pl --dir=/home/jasons/work/GeneX-Server/Genex --target=AL_Spots --support=SpotLink
#
# cvs id: $Id: AL_Spots.pm,v 1.13 2001/02/06 18:58:51 jes Exp $ 
#
##############################
package Bio::Genex::AL_Spots;

use strict;
use POSIX 'strftime';
use Carp;
use DBI;
use IO::File;
use Bio::Genex::DBUtils qw(:CREATE
		      :ASSERT
		      fetch_last_id
		     );
# import the fkey constants and undefined
use Bio::Genex qw(undefined);
use Bio::Genex::Fkey qw(:FKEY);

use Class::ObjectTemplate::DB 0.21;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $FKEYS $COLUMN2NAME $NAME2COLUMN $COLUMN_NAMES %_CACHE $USE_CACHE $LIMIT $FKEY_OBJ2RAW $TABLE2PKEY);

require Exporter;

@ISA = qw(Class::ObjectTemplate::DB Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw();

BEGIN {
  $USE_CACHE = 1;

  %_CACHE = ();

  $COLUMN_NAMES = [
          'als_pk',
          'al_fk',
          'spot_type',
          'spot_identifier',
          'spot_description',
          'usf_fk',
          'sub_sequence_start',
          'sub_sequence_end',
          'spot_concentration',
          'x_image_location',
          'y_image_location',
          'grid_image_location'
        ]
;
 $FKEYS = {
          'usf_obj' => bless( {
                                'table_name' => 'UserSequenceFeature',
                                'fkey_type' => 'FKEY_OO',
                                'fkey_name' => 'usf_obj',
                                'pkey_name' => 'usf_pk'
                              }, 'Bio::Genex::Fkey' ),
          'al_obj' => bless( {
                               'table_name' => 'ArrayLayout',
                               'fkey_type' => 'LOOKUP_TABLE_OO',
                               'fkey_name' => 'al_obj',
                               'pkey_name' => 'al_pk'
                             }, 'Bio::Genex::Fkey' ),
          'spotlink_fk' => bless( {
                                    'table_name' => 'SpotLink',
                                    'fkey_type' => 'ONE_TO_MANY_LINK',
                                    'fkey_name' => 'spotlink_fk',
                                    'pkey_name' => 'als_fk'
                                  }, 'Bio::Genex::Fkey' ),
          'spotlink_obj' => bless( {
                                     'fkey_type' => 'ONE_TO_MANY_LINK_OO',
                                     'table_name' => 'SpotLink',
                                     'fkey_name' => 'spotlink_obj',
                                     'pkey_name' => 'als_fk'
                                   }, 'Bio::Genex::Fkey' )
        }
;

  $COLUMN2NAME  = {
          'sub_sequence_end' => 'Sub-sequence End',
          'al_fk' => 'Array Layout',
          'grid_image_location' => 'Grid Image Location',
          'als_pk' => 'Accession Number',
          'spot_identifier' => 'Spot Identifier',
          'spot_concentration' => 'Spot Concentration',
          'usf_fk' => 'User Sequence Feature',
          'spot_description' => 'Spot Description',
          'y_image_location' => 'Y Image Location',
          'x_image_location' => 'X Image Location',
          'sub_sequence_start' => 'Sub-sequence Start',
          'spot_type' => 'Spot Type'
        }
;
  $NAME2COLUMN  = {
          'Grid Image Location' => 'grid_image_location',
          'Accession Number' => 'als_pk',
          'Spot Description' => 'spot_description',
          'Sub-sequence End' => 'sub_sequence_end',
          'Y Image Location' => 'y_image_location',
          'X Image Location' => 'x_image_location',
          'Sub-sequence Start' => 'sub_sequence_start',
          'User Sequence Feature' => 'usf_fk',
          'Spot Type' => 'spot_type',
          'Array Layout' => 'al_fk',
          'Spot Identifier' => 'spot_identifier',
          'Spot Concentration' => 'spot_concentration'
        }
;
  $FKEY_OBJ2RAW = {
          'usf_obj' => 'usf_fk',
          'al_obj' => 'al_fk',
          'spotlink_obj' => 'spotlink_fk'
        }
;
}


attributes (no_lookup=>['fetched', 'fetch_all', 'fetched_attr', 'id'], lookup=>['als_pk', 'al_fk', 'spot_type', 'spot_identifier', 'spot_description', 'usf_fk', 'sub_sequence_start', 'sub_sequence_end', 'spot_concentration', 'x_image_location', 'y_image_location', 'grid_image_location', 'usf_obj', 'spotlink_obj', 'spotlink_fk', 'al_obj']);

sub table_name {return 'AL_Spots';} # probably unnecessary

sub fkeys {return $FKEYS;}

sub column2name {return $COLUMN2NAME;}

sub name2column {return $NAME2COLUMN;}

sub fkey_obj2raw {return $FKEY_OBJ2RAW;}

sub column_names {return $COLUMN_NAMES;}

sub pkey_name {return 'als_pk';}

sub linking_table {return 0;}
sub insert_db {
  my ($self,$dbh) = @_;
  assert_dbh($dbh);

  # iterate over the fields and add them to the INSERT
  my %values;
  foreach my $col (@{$COLUMN_NAMES}) {
    no strict 'refs';

    # we don't want Bio::Genex::undefined() to get called
    next unless defined $self->get_attribute($col);

    $values{$col} = $self->$col();
  }

  # don't store a primary key
  delete $values{'als_pk'};

  if (grep {$_ eq 'last_updated'} @{$COLUMN_NAMES}) {
    # we set the 'last_updated' field ourselves
    my $timeformat = '%r %A %B %d %Y'; 
    $values{last_updated} = strftime($timeformat, localtime);
  }

  # execute the INSERT
  my $sql = create_insert_sql($dbh,'AL_Spots',\%values);
  $dbh->do($sql);
  
  # on error
  if ($dbh->err) {
    warn "Bio::Genex::AL_Spots::insert_db: SQL=<$sql>, DBI=<$DBI::errstr>";
    return undef;
  }
  my $pkey = fetch_last_id($dbh,'AL_Spots');
  $self->id($pkey);
  $self->als_pk($pkey);
  return $pkey;
}

sub update_db {
  my ($self,$dbh) = @_;
  assert_dbh($dbh);
  die "Bio::Genex::AL_Spots::update_db: object not in DB"
    unless defined $self->id() && defined $self->als_pk();

  # we must pre-fetch all the attributes 
  $self->fetch();

  # iterate over the fields and add them to the INSERT
  my %values;
  foreach my $col (@{$COLUMN_NAMES}) {
    no strict 'refs';

    # we don't want Bio::Genex::undefined() to get called
    next unless defined $self->get_attribute($col);

    $values{$col} = $self->$col();
  }

  if (grep {$_ eq 'last_updated'} @{$COLUMN_NAMES}) {
    # we set the 'last_updated' field ourselves
    my $timeformat = '%r %A %B %d %Y'; 
    $values{last_updated} = strftime($timeformat, localtime);
  }

  # execute the UPDATE
  my $WHERE = 'als_pk=' . $dbh->quote($self->als_pk());
  my $sql = create_update_sql($dbh,
			      TABLE=>'AL_Spots',
			      SET=>\%values,
			      WHERE=>$WHERE);
  $dbh->do($sql);

  # on error
  if ($dbh->err) {
    warn "Bio::Genex::AL_Spots::update_db: SQL=<$sql>, DBI=<$DBI::errstr>";
    return undef;
  }
  return 1;
}
#
# a workhorse function for retrieving ALL objects of a class
#
sub get_all_objects {
  my ($class) = shift;
  my @objects;
  my $COLUMN2FETCH;
  my $VALUE2FETCH;
  my $pkey_name;
  my $has_args = 0;
  $pkey_name = $class->pkey_name();
  if (ref($_[0]) eq 'HASH') {
    # we were called with an anonymous hash as the first parameter
    # grab it and parse the parameter => value pairs
    my $hashref = shift;
    $has_args = 1;
    $COLUMN2FETCH =  $hashref->{column} if exists $hashref->{column};
    $VALUE2FETCH =  $hashref->{value} if exists $hashref->{value};
    die "Bio::Genex::AL_Spots::get_all_objects: Must define both 'column' and 'value'" 
      if ((defined $VALUE2FETCH) && not (defined $COLUMN2FETCH)) || 
          ((defined $COLUMN2FETCH) && not (defined $VALUE2FETCH));
  }

  my @ids;

  # using class methods seems indirect, but it deals
  # properly with inheritance
  my $FROM = [$class->table_name()];

  # we fetch *all* columns, so that we can populate the new objects
  my $COLUMNS = ['*'];

  my $dbh = Bio::Genex::current_connection();
  my @args = (COLUMNS=>$COLUMNS, FROM=>$FROM);
  if (defined $COLUMN2FETCH) {
    my $where =  "$COLUMN2FETCH = ". $dbh->quote($VALUE2FETCH);
    push(@args,WHERE=>$where);
  }
  push(@args,LIMIT=>$LIMIT) if defined $LIMIT;
  my $sql = create_select_sql($dbh,@args);
  my $sth = $dbh->prepare($sql) 
    or die "Bio::Genex::AL_Spots::get_all_objects:\nSQL=<$sql>,\nDBI=<$DBI::errstr>";
  $sth->execute() 
    or die "Bio::Genex::AL_Spots::get_all_objects:\nSQL=<$sql>,\nDBI=<$DBI::errstr>";

  # if there were no objects, return. decide whether to return an 
  # empty list or an empty arrayref using wantarray
  unless ($sth->rows()) {
    return () if wantarray;
    return []; # if not wantarray
  }

  # we use the 'NAME' attribute of the statement handle to get the
  # list of columns that were fetched.
  my @column_names = @{$sth->{NAME}};
  my $rows = $sth->fetchall_arrayref();
  die "Bio::Genex::AL_Spots::get_all_objects:\nSQL=<$sql>,\nDBI=<$DBI::errstr>" 
    if $sth->err;
  foreach my $col_ref (@{$rows}) {
    # we create a blank object, and populate it with data ourselves
    my $obj = $class->new();

    # %fetched_attrs is used to track which attributes have
    # already been retrieved from the DB, so that Bio::Genex::undefined
    # doesn't try to fetch them a second time if their value is undef
    my %fetched_attrs;
    for (my $i=0;$i < scalar @column_names; $i++) {
      no strict 'refs';
      my $col = $column_names[$i];
      $obj->$col($col_ref->[$i]);

      # record the column as fetched
      $fetched_attrs{$col}++;
    }
    # store the record of the fetched columns
    $obj->fetched_attr(\%fetched_attrs);
    $obj->fetched(1);

    # now we set the id so that delayed-fetching will work for
    # the OO attributes
    $obj->id($obj->get_attribute("$pkey_name"));
    push(@objects,$obj);
  }
  $sth->finish();

  # decide whether to return a list or an arrayref using wantarray
  return @objects if wantarray;
  return \@objects; # if not wantarray
}

#
# a workhorse function for retrieving multiple objects of a class
#
sub get_objects {
  my ($class) = shift;
  my @objects;
  if (ref($_[0]) eq 'HASH' || scalar @_ == 0) {
    croak("Bio::Genex::AL_Spots::get_objects called with no ID's, perhaps you meant to use Bio::Genex::AL_Spots::get_all_objects
");
  } 
  my @ids = @_;
  my $obj;
  foreach (@ids) {
    if ($USE_CACHE && exists $_CACHE{$_}) {
	$obj = $_CACHE{$_};	# use it if it's in the cache
    } else {
	my @args = (id=>$_);
	$obj = $class->new(@args);

	# if the id was bad, $obj will be undefined
	next unless defined $obj;
	$_CACHE{$_} = $obj if $USE_CACHE; # stick it in the cache for later
    }
    push(@objects, $obj);
  }
  # decide whether to return a list or an arrayref using wantarray
  return @objects if wantarray;
  return \@objects; # if not wantarray
}

#
# Lookup table classes need the ability to return themselves as an
# array of hash refs.
#
sub get_matrix {
  my ($class,@args) = @_;

  my %args = (FROM=>['AL_Spots']);
  if (scalar @args == 1 && ref($args[0]) ne 'ARRAY') {
    # fetch all spots from a single array, without restriction
   $args{WHERE} = "al_fk = '$args[0]'";
   $args{COLUMNS} = ['als_pk', 'spot_type', 'spot_identifier', 'spot_description', 'usf_fk', 'sub_sequence_start', 'sub_sequence_end', 'spot_concentration', 'x_image_location', 'y_image_location', 'grid_image_location'];
                  
  } else {
    # fetch spots with restriction
    my $WHERE;
    my @column_names = @{$class->column_names()};
    foreach my $arg (@args) {
      die "Not an array ref: $arg" unless ref($arg) eq 'ARRAY';

      # now check that the column is valid using a regexp
      die "Bad column name: $arg->[0]" 
        unless grep {$_ eq $arg->[0]} @column_names;

      $WHERE .= ' AND ' if defined $WHERE;
      my $list = join(", ", @{$arg->[1]});
      $WHERE .= " $arg->[0] IN ($list) ";
    }
    $args{WHERE} = $WHERE;
    $args{COLUMNS} = ['als_pk', 'al_fk', 'spot_type', 'spot_identifier', 'spot_description', 'usf_fk', 'sub_sequence_start', 'sub_sequence_end', 'spot_concentration', 'x_image_location', 'y_image_location', 'grid_image_location'];
  }

  $args{LIMIT} = $LIMIT if defined $LIMIT;
  # create_select_sql() now needs a database handle
  my $dbh = Bio::Genex::current_connection();
  my $sql = create_select_sql($dbh,%args);

  my $sth = $dbh->prepare($sql) || die "Bio::Genex::AL_Spots::get_matrix: $DBI::errstr";
  $sth->execute() || die "Bio::Genex::AL_Spots::get_matrix: $DBI::errstr";

  # if we didn't retrieve any rows, return an empty arrayref
  return [] unless $sth->rows();
  my @objects;
  push(@objects,$args{COLUMNS}); # add a header for legibility

  while (my @vals = $sth->fetchrow_array()) {
    # we have to make the copy, otherwise we reuse the address
    die "Bio::Genex::AL_Spots::get_matrix: $DBI::errstr" if $sth->err;
    push(@objects,\@vals);
  }
  $sth->finish();
  return \@objects;
}


# ObjectTemplate automagically creates a new() method for us 
# that method invokes $self->initialize() after first setting all 
# parameters specified in invocation
sub initialize {
  my $self = shift;

  # we only need to be concerned with caching and id verification
  # if the user has specified and 'id'.
  my $id = $self->get_attribute('id');
  if (defined $id) {
    # 
    # executive decision: if it's in the cache, use it without
    # checking that the parameters are the same
    return $_CACHE{$id} if $USE_CACHE && 
      defined $id &&
      exists $_CACHE{$id};
  
    # 
    # The object is not in the cache, so now we check whether we've
    # been given a valid id
    #
    my $pkey_name = $self->pkey_name();
    my $dbh = Bio::Genex::current_connection();
    my $FROM = [$self->table_name()];
    my $COLUMNS = [$pkey_name];
    my @args = (COLUMNS=>$COLUMNS, FROM=>$FROM, 
  		WHERE=> $pkey_name . " = '$id'");
    my $sql = create_select_sql($dbh,@args);
    my $count = scalar @{$dbh->selectall_arrayref($sql)};
    die "Bio::Genex::AL_Spots::initialize: $DBI::errstr" if $dbh->err;
  
    # if there was a problem, return an error to new(), so that 
    # new will return undef to the calling function
    if ($count < 1) {
      warn("Bio::Genex::AL_Spots::initialize: no DB entries for id: $id");
      return -1 unless $count > 0;
    }
  }

  #
  # now that we know we have a valid id, we can resume initialization
  #

  # we need to initialize these for Bio::Genex::undefined() to work
  $self->fetched(0);		# we have not retrieved data via fetch
  $self->fetched_attr({});	# no attr's have been delayed_fetched

  # actually get the object's data if we've been told to
  if (defined $self->get_attribute('fetch_all')) {
    die "Can't use 'fetch_all' without setting 'id'" unless defined $id;
    $self->fetch();
  }
}

sub fetch {
  my ($self) = @_;

  # recursion in this is bad
  return if $self->fetched();

  # can't fetch without a primary key to lookup the data
  my $pkey = $self->get_attribute('id');
  die "Must define an id for fetch"  unless defined $pkey;

  # we don't want to get into loops in Bio::Genex::undefined()
  $self->fetched(1);

  my $dbh = Bio::Genex::current_connection();

  # we make these method calls instead of hardcoding the values
  # for the purpose of inheritance
  assert_table_defined($dbh,$self->table_name());
  my $sql = create_select_sql($dbh,
                    COLUMNS=>['als_pk', 'al_fk', 'spot_type', 'spot_identifier', 'spot_description', 'usf_fk', 'sub_sequence_start', 'sub_sequence_end', 'spot_concentration', 'x_image_location', 'y_image_location', 'grid_image_location'],
                    FROM=>[$self->table_name()],
                    WHERE=>$self->pkey_name() . " = '$pkey'",
                              );
  my $sth = $dbh->prepare($sql) || die "Bio::Genex::AL_Spots::initialize: $DBI::errstr";
  $sth->execute() || die "Bio::Genex::AL_Spots::initialize: $DBI::errstr";

  # sanity check to see if bogus id
  my $ref = $sth->fetchrow_hashref();
  die "AL_Spots: ", $self->pkey_name(), " $pkey, not in DB"
    unless defined $ref;

  while (my ($key,$val) = each %{$ref}) {
    # no use for storing undef, since all attributes 
    # start as undef
    next unless defined $val;

    # we only want to set attributes that do not already exist
    # for example, we are called by update_db(), we don't want to force
    # users to call fetch() before modifying the object's attributes
    next if defined $self->get_attribute($key);

    { # we use this to temporarily relax the strict pragma
      # to use symbolic references
      no strict 'refs';
      $self->$key($val);
    } # back to our regularily scheduled strictness
  }
  $sth->finish();
}


=head1 NAME

Bio::Genex::AL_Spots - Methods for processing data from the GeneX DB
 table: AL_Spots

=head1 SYNOPSIS

  use Bio::Genex::AL_Spots;

  # instantiating an instance
  my $AL_Spots = Bio::Genex::AL_Spots->new(id=>47);

  # retrieve data from the DB for all columns
  $AL_Spots->fetch();

  # creating an instance, without pre-fetching all columns
  my $AL_Spots = new Bio::Genex::AL_Spots(id=>47);

  # creating an instance with pre-fetched data
  my $AL_Spots = new Bio::Genex::AL_Spots(id=>47, 'fetch_all'=>1);

  # retrieving multiple instances via primary keys
  my @objects = Bio::Genex::AL_Spots->get_objects(23,57,98)


  # retrieving all instances from a table
  my @objects = Bio::Genex::AL_Spots->get_all_objects();

  # retrieving the primary key for an object, generically
  my $primary_key = $AL_Spots->id();

  # or specifically
  my $als_pk_val = $AL_Spots->als_pk();

  # retreving other DB column attributes
  my $al_fk_val = $AL_Spots->al_fk();
  $AL_Spots->al_fk($value);

  my $spot_type_val = $AL_Spots->spot_type();
  $AL_Spots->spot_type($value);

  my $spot_identifier_val = $AL_Spots->spot_identifier();
  $AL_Spots->spot_identifier($value);

  my $spot_description_val = $AL_Spots->spot_description();
  $AL_Spots->spot_description($value);

  my $usf_fk_val = $AL_Spots->usf_fk();
  $AL_Spots->usf_fk($value);

  my $sub_sequence_start_val = $AL_Spots->sub_sequence_start();
  $AL_Spots->sub_sequence_start($value);

  my $sub_sequence_end_val = $AL_Spots->sub_sequence_end();
  $AL_Spots->sub_sequence_end($value);

  my $spot_concentration_val = $AL_Spots->spot_concentration();
  $AL_Spots->spot_concentration($value);

  my $x_image_location_val = $AL_Spots->x_image_location();
  $AL_Spots->x_image_location($value);

  my $y_image_location_val = $AL_Spots->y_image_location();
  $AL_Spots->y_image_location($value);

  my $grid_image_location_val = $AL_Spots->grid_image_location();
  $AL_Spots->grid_image_location($value);


=head1 DESCRIPTION

Each Genex class has a one to one correspondence with a GeneX DB table
of the same name (I<i.e.> the corresponding table for Bio::Genex::AL_Spots is
AL_Spots).


Most applications will first create an instance of Bio::Genex::AL_Spots
and then fetch the data for the object from the DB by invoking
C<fetch()>. However, in cases where you may only be accessing a single
value from an object the built-in L<delayed fetch|/DELAYED_FETCH>
mechanism can be used. All objects are created without pre-fetching
any data from the DB. Whenever an attribute of the object is accessed
via a getter method, the data for that attribute will be fetched from
the DB if it has not already been. Delayed fetching happens
transparently without the user needing to enable or disable any
features. 

Since data is not be fetched from the DB I<until> it is accessed by
the calling application, it could presumably save a lot of access time
for large complicated objects when only a few attribute values are
needed.

=head1 ATTRIBUTES

There are three different types of attributes which instances of
Bio::Genex::AL_Spots can access: I<raw> foreign key attributes,
Obect-Oriented foreign key attributes, and simple column attributes.

=over 4 

=item Raw Foreign Keys Attributes

=item Object Oriented Foreign Key Attributes

This mode presents foreign key attributes in a special way, with all
non-foreign key attributes presented normally. Foreign keys are first
retrieved from the DB, and then objects of the appropriate classes are
created and stored in slots. This mode is useful for applications that
want to process information from the DB because it automates looking
up information.

Specifying the 'C<recursive_fetch>' parameter when calling C<new()>,
modifies the behavior of this mode. The value given specifies the
number of levels deep that fetch will be invoked on sub-objects
created.

=item Simple Column Attributes

=back



=head1 CLASS VARIABLES

Class Bio::Genex::AL_Spots defines the following utility variables for assisting
programmers to access the AL_Spots table.

=over 4

=item $Bio::Genex::AL_Spots::LIMIT

If defined, $LIMIT will set a limit on any select statements that can
return multiple instances of this class (for example C<get_objects()>
or any call to a C<ONE_TO_MANY> or C<LOOKUP_TABLE> foreign key
accessor method).


=item $Bio::Genex::AL_Spots::USE_CACHE

This variable controls whether the class will cache any objects
created in calls to C<new()>. Objects are cached by primary key. The
caching is very simple, and no effort is made to track whether
different invocations of C<new()> are being made for an object with
the same primary key value, but with different options set. If you
desire to reinstantiate an object with a different set of parameters,
you would need to undefine C<$USE_CACHE> first.


=back


B<WARNING>: variables other than those listed here are for internal use
only and are subject to change without notice. Use them at your own
risk.

=head1 DELAYED FETCH

It is possible to retrieve only the subset of attributes one chooses
by simply creating an object instance and then calling the appropriate
getter function. The object will automatically fetch the value from
the DB when requested. This can potentially save time for large
complicated objects. This triggers a separate DB query for each
attribute that is accessed, whereas calling C<fetch()> will retrieve
all fields of the object with a single query.

For example:

  my $AL_Spots = Bio::Genex::AL_Spots->new(id=>47);
  my $val = $AL_Spots->als_pk();

The attribute's value is then cached in the object so any further calls
to that attribute's getter method do not trigger a DB query.

B<NOTE>: Methods may still return C<undef> if their value in
the DB is C<NULL>.


=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Bio::Genex::AL_Spots->methodname() syntax.

=over 4

=item new(%args)

new() accepts the following arguments:

=over 4

=item id 

Numeric or string value. The value of the primary key for looking up
the object in the DB.

=back

=item linking_table()

Used by generic functions to determine if a specified class is a
linking table class. For Bio::Genex::AL_Spots it returns 0, since it is
I<not> a linking table class.

=item pkey_name()

This method returns the name of the column which is used as the
primary key for this DB table. This method only exists for non-linking
table classes, and for Bio::Genex::AL_Spots it returns the value 'als_pk';


=item table_name()

Returns the name of the DB table represented by this class. For
Bio::Genex::AL_Spots it returns 'AL_Spots';

=item column2name()

This method returns a hashref that translates DB column names into
human readable format.

=item name2column()

This method returns a hashref that is a reverse lookup table to
translate the human readable version of a DB column name back into the
column_name. This is useful for preparing table output in CGI scripts:


    %column2name = %{$class->column2name()};
    if (exists $column2name{$_}) {
      push(@column_copy,$column2name{$_});
    }
    
    # now that we've translated the names, we sort them
    @column_copy = sort @column_copy;
    
    # make a header element. 
    push(@rows,th(\@column_copy));


=item fkeys()

This method returns a hashref that holds all the foreign key entries
for the AL_Spots table.

=item column_names()

This method returns an array ref which holds the names of all the
columns in table AL_Spots.


    # first retrieve the data from the DB
    $object = $full_module_name->new(id=>$id);
    $object->fetch();

    # now extract the data from the object
    foreach (@{$class->column_names}) {
    # we use this to temporarily relax the strict pragma
    # to use symbolic references
      no strict 'refs';
      $tmp_values{$_} = $object->$_;

    # back to our regularily scheduled strictness
    }


=item get_matrix($id)

=item get_matrix([$col_name=>[@allowed_list], [$other_col=>[@list]]])

For efficiency reasons, lookup table classes, like $full_module_name
need to be able to return their data in a matrix of values, and not a
list of objects. 

The simple form is called with a single parameter, $id, that specifies
the the value of the C<LOOKUP_TABLE> foreign key to use in DB query.

The more complex interface allows a user to restrict the values
returned by $column_names and a @list of allowed values that that
column may have. Multiple $column_name/@list pairs may be specified
and the restrictions will all be AND\'ed together in the SQL WHERE
clause.



=item insert_db($dbh)

This method inserts the data for the object into the database
specified by the DB handle $dbh. To use this method, create a blank
object with C<new()>, set the attributes that you want, and then call
C<insert_db()>.

  my $dbh = Bio::Genex::current_connection(USER=>$SU_USERNAME,
                                      PASSWORD=>$SU_PASSWORD);
  my AL_Spots = Bio::Genex::AL_Spots->new();
  AL_Spots->al_fk('some_value');
  AL_Spots->insert_db($dbh);

B<NOTE:> You must log into the DB with a user/password that has INSERT
priveleges in the DB, otherwise you will get a DBI error.

B<WARNING:> C<fetch()> will I<not> be called, so if you are using this
method to insert a copy of an existing DB object, then it is up to you
to call C<fetch()>, otherwise, only the attributes that are currently
set in the object will be inserted.

=item update_db($dbh)

This method update the data for an object already in the database
specified by the DB handle $dbh. To use this method, fetch an
object from the DB, change the attributes that you want, and then call
C<update_db()>.

  my $dbh = Bio::Genex::current_connection(USER=>$SU_USERNAME,
                                      PASSWORD=>$SU_PASSWORD);
  my AL_Spots = Bio::Genex::AL_Spots->new(id=>43);
  AL_Spots->al_fk('some_value');
  AL_Spots->update_db($dbh);

B<NOTE:> You must log into the DB with a user/password that has INSERT
priveleges in the DB, otherwise you will get a DBI error.

B<NOTE:> Any modification of the primary key value will be discarded
('als_pk' for module Bio::Genex::AL_Spots).

=item get_objects(@id_list)

=item get_all_objects()

=item get_objects({column=>'col_name',value=>'val'})

This method is used to retrieve multiple instances of class Bio::Genex::AL_Spots
simultaneously. There are three different ways to invoke this method.

By passing in an C<@id_list>, get_objects() uses each element of the
list as a primary key for the AL_Spots table and returns a single
instance for each entry.

B<WARNING>: Passing incorrect id values to C<get_objects()> will cause
a warning from C<Bio::Genex::AL_Spots::initialize()>. Objects will be
created for other correct id values in the list.

C<get_all_objects()> returns an instance for every entry in the table.

By passing an anonymous hash reference that contains the 'column' and
'name' keys, the method will return all objects from the DB whose that
have the specified value in the specified column.


=back



B<NOTE>: All objects must have the 'id' parameter set before attempting
to use C<fetch()> or any of the objects getter functions.

=head1 INSTANCE METHODS

The following methods can only be called by first having valid
instance of class Bio::Genex::AL_Spots.

=over 4


=item fetch()

This method triggers a DB query to retrieve B<ALL> columns from the DB
associated with this object.


=back



B<WARNING>: methods other than those listed here are for internal use
only and are subject to change without notice. Use them at your own
risk.


=head1 FOREIGN KEY ACCESSOR METHODS

There are two major categories of foreign key accessor methods:
I<Object Oriented> foreign key methods, and I<raw> foreign key
methods. 

Each foreign key column in the table is represented by B<two> methods,
one OO method and one raw method. The raw method enables fethcing the
exact numeric or string values stored in the DB. The OO method creates
objects of the class the fkey column refers to. The idea is that if
only the numeric fkey value is desired, the raw fkey method can be
used. If it is necessary to get attributes from the table referred to
by the fkey column, then the OO method should be invoked, and the
necessary methods on that object can be queried.

The names of the raw fkey methods is the same as the fkey columns in
the DB table they represent (all fkey columns end in the suffix
'_fk'). The OO methods have the same names as the column they
represent, with the difference that they have the suffix '_obj'
instead of '_fk'.

So for example, in class Bio::Genex::ArrayMeasurement the
'C<primary_es_fk>' column is represented by two methods, the raw
method C<primary_es_fk()>, and the OO method C<primary_es_obj>.

The following foreign key accessors are defined for class
Bio::Genex::AL_Spots:

=over 4


=item @id_list = spotlink_fk()

=item @obj_list = spotlink_obj()

This is an attribute of type ONE_TO_MANY_LINK and refers to class
L<Bio::Genex::SpotLink>. The raw accessor method, C<spotlink_fk()> returns a list of
foreign key ids. The OO accessor method, C<spotlink_obj()> returns a
list of objects of class Bio::Genex::SpotLink.


=back



Every foreign key in a DB table belongs to a certain class of foreign
keys. Each type of foreign key confers a different behavior on the
class that contains it. The classifications used in Genex.pm are:

=over 4

=item *

MANY_TO_ONE

If a class contains a foreign key of this type it will not be visible
to the API of that class, but instead it confers a special method to
the class that it references. 

For example, the Chromosome table has a MANY_TO_ONE foreign key,
spc_fk, that refers to the species table. Class L<Bio::Genex::Chromosome>, has
it\'s normal C<spc_fk()> attribute method, but no special foreign key
accessor method. However, class L<Bio::Genex::Species> is given a special
foreign key accessor method, C<chromosome_fk()> of type
ONE_TO_MANY. When invoked, this method returns a list of objects of
class L<Bio::Genex::Species>.

=item *

ONE_TO_MANY

The inverse of type MANY_TO_ONE. It is not an attribute inherent to a
given foreign key in any DB table, but instead is created by the
existence of a MANY_TO_ONE foreign key in another table. See the above
discussion about MANY_TO_ONE foreign keys.

=item *

LOOKUP_TABLE

This type of key is similar to type ONE_TO_MANY. However, However the
API will I<never> retrieve an object of this type. Instead it
retrieves a matrix of values, that represent the list of objects. It
is used in only two places in the API: L<Bio::Genex::ArrayMeasurement> and
L<Bio::Genex::ArrayLayout> classes with the C<am_spots()> and C<al_spots()>
accessor functions.

=item *

LINKING_TABLE

Foreign keys of this type appear in tables without primary keys. The
foreign keys are each of type LINKING_TABLE, and when invoked return
an object of the class referred to by the foreign key.

=item *

FKEY

A generic foreign key with no special properties. When invoked it returns
an object of the class referred to by the foreign key.

=back




=head1 ATTRIBUTE METHODS

These are the setter and getter methods for attributes in class
Bio::Genex::AL_Spots.

B<NOTE>: To use the getter methods, you may either invoke the
C<fetch()> method to retrieve all the values for an object, or else
rely on L<delayed fetching|/DELAYED_FETCH> to retrieve the attributes
as needed.

=over 4


=item id()

C<id()> is a special attribute method that is common to all the Genex
classes. This method returns the primary key of the given instance
(and for class Bio::Genex::AL_Spots it is synonomous with the
C<als_pk()>method). The C<id()> method can be useful in writing
generic methods because it avoids having to know the name of the
primary key column. 

=item als_pk()

This is the primary key attribute for Bio::Genex::AL_Spots. It has no setter method. 


=item $value = al_fk();

=item al_fk($value);

Methods for the al_fk attribute.


=item $value = spot_type();

=item spot_type($value);

Methods for the spot_type attribute.


=item $value = spot_identifier();

=item spot_identifier($value);

Methods for the spot_identifier attribute.


=item $value = spot_description();

=item spot_description($value);

Methods for the spot_description attribute.


=item $value = usf_fk();

=item usf_fk($value);

Methods for the usf_fk attribute.


=item $value = sub_sequence_start();

=item sub_sequence_start($value);

Methods for the sub_sequence_start attribute.


=item $value = sub_sequence_end();

=item sub_sequence_end($value);

Methods for the sub_sequence_end attribute.


=item $value = spot_concentration();

=item spot_concentration($value);

Methods for the spot_concentration attribute.


=item $value = x_image_location();

=item x_image_location($value);

Methods for the x_image_location attribute.


=item $value = y_image_location();

=item y_image_location($value);

Methods for the y_image_location attribute.


=item $value = grid_image_location();

=item grid_image_location($value);

Methods for the grid_image_location attribute.


=back



B<WARNING>: methods other than those listed here are for internal use
only and are subject to change without notice. Use them at your own
risk.

=head1 IMPLEMENTATION DETAILS

These classes are automatically generated by the
create_genex_classes.pl script.  Each class is a subclass of the
Class::ObjectTemplate::DB class (which is in turn a subclass of
Class::ObjectTemplate written by Sriram Srinivasan, described in
I<Advanced Perl Programming>, and modified by Jason
Stewart). ObjectTemplate implements automatic class creation in perl
(there exist other options such as C<Class::Struct> and
C<Class::MethodMaker> by Damian Conway) via an C<attributes()> method
call at class creation time.

=head1 BUGS

Please send bug reports to genex@ncgr.org

=head1 LAST UPDATED

on Mon Feb  5 21:23:56 2001 by /home/jasons/work/GeneX-Server/Genex/scripts/create_genex_class.pl --dir=/home/jasons/work/GeneX-Server/Genex --target=AL_Spots --support=SpotLink

=head1 AUTHOR

Jason E. Stewart (jes@ncgr.org)

=head1 SEE ALSO

perl(1).

=cut

1;
