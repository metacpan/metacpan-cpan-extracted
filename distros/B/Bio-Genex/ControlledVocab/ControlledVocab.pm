##############################
#
# Bio::Genex::ControlledVocab
#
# created on Mon Feb  5 21:24:01 2001 by /home/jasons/work/GeneX-Server/Genex/scripts/create_genex_class.pl --dir=/home/jasons/work/GeneX-Server/Genex --target=ControlledVocab --pkey=term_string --controlled=AL_Coating --controlled=AL_DefaultSpotConcUnits --controlled=AL_TechnologyType --controlled=AL_Medium --controlled=AL_IdentifierCode --controlled=ALS_SpotType --controlled=AM_EquationType --controlled=AM_SpotMeasurementUnits --controlled=AM_Type --controlled=ContactType --controlled=EF_MajorCategory --controlled=EF_MinorCategory --controlled=ES_QuantitySeriesType --controlled=ES_TreatmentType --controlled=HS_ThresholdType --controlled=PRT_Type --controlled=SCN_ModelDescription --controlled=SMP_AgeUnits --controlled=SMP_DevelopmentStageName --controlled=SMP_DevelopmentStageUnits --controlled=SMP_GeneticStatus --controlled=SMP_OrganismIntactness --controlled=SMP_OrganType --controlled=SMP_PrimaryCellType --controlled=SMP_SexMatingType --controlled=SMP_TissueType --controlled=SPC_GeneralClassification --controlled=SPC_CellStructure --controlled=SPT_ModelDescription --controlled=SW_Name --controlled=SW_Type --controlled=USF_Type
#
# cvs id: $Id: ControlledVocab.pm,v 1.13 2001/02/06 18:58:52 jes Exp $ 
#
##############################
package Bio::Genex::ControlledVocab;

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
          'term_string',
          'description'
        ]
;
 $FKEYS = {}
;

  $COLUMN2NAME  = {
          'description' => 'Description',
          'term_string' => 'Term String'
        }
;
  $NAME2COLUMN  = {
          'Description' => 'description',
          'Term String' => 'term_string'
        }
;
  $FKEY_OBJ2RAW = {}
;
}


attributes (no_lookup=>['fetched', 'fetch_all', 'fetched_attr', 'id'], lookup=>['term_string', 'description']);

sub table_name {return 'ControlledVocab';} # probably unnecessary

sub fkeys {return $FKEYS;}

sub column2name {return $COLUMN2NAME;}

sub name2column {return $NAME2COLUMN;}

sub fkey_obj2raw {return $FKEY_OBJ2RAW;}

sub column_names {return $COLUMN_NAMES;}

sub pkey_name {return 'term_string';}

sub linking_table {return 0;}

sub get_terms {
  return map {$_->term_string} shift->get_all_objects();
}
sub get_vocabs {
  return qw(AL_Coating AL_DefaultSpotConcUnits AL_TechnologyType AL_Medium AL_IdentifierCode ALS_SpotType AM_EquationType AM_SpotMeasurementUnits AM_Type ContactType EF_MajorCategory EF_MinorCategory ES_QuantitySeriesType ES_TreatmentType HS_ThresholdType PRT_Type SCN_ModelDescription SMP_AgeUnits SMP_DevelopmentStageName SMP_DevelopmentStageUnits SMP_GeneticStatus SMP_OrganismIntactness SMP_OrganType SMP_PrimaryCellType SMP_SexMatingType SMP_TissueType SPC_GeneralClassification SPC_CellStructure SPT_ModelDescription SW_Name SW_Type USF_Type);
}
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
  delete $values{'term_string'};

  if (grep {$_ eq 'last_updated'} @{$COLUMN_NAMES}) {
    # we set the 'last_updated' field ourselves
    my $timeformat = '%r %A %B %d %Y'; 
    $values{last_updated} = strftime($timeformat, localtime);
  }

  # execute the INSERT
  my $sql = create_insert_sql($dbh,'ControlledVocab',\%values);
  $dbh->do($sql);
  
  # on error
  if ($dbh->err) {
    warn "Bio::Genex::ControlledVocab::insert_db: SQL=<$sql>, DBI=<$DBI::errstr>";
    return undef;
  }
  my $pkey = fetch_last_id($dbh,'ControlledVocab');
  $self->id($pkey);
  $self->term_string($pkey);
  return $pkey;
}

sub update_db {
  my ($self,$dbh) = @_;
  assert_dbh($dbh);
  die "Bio::Genex::ControlledVocab::update_db: object not in DB"
    unless defined $self->id() && defined $self->term_string();

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
  my $WHERE = 'term_string=' . $dbh->quote($self->term_string());
  my $sql = create_update_sql($dbh,
			      TABLE=>'ControlledVocab',
			      SET=>\%values,
			      WHERE=>$WHERE);
  $dbh->do($sql);

  # on error
  if ($dbh->err) {
    warn "Bio::Genex::ControlledVocab::update_db: SQL=<$sql>, DBI=<$DBI::errstr>";
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
    die "Bio::Genex::ControlledVocab::get_all_objects: Must define both 'column' and 'value'" 
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
    or die "Bio::Genex::ControlledVocab::get_all_objects:\nSQL=<$sql>,\nDBI=<$DBI::errstr>";
  $sth->execute() 
    or die "Bio::Genex::ControlledVocab::get_all_objects:\nSQL=<$sql>,\nDBI=<$DBI::errstr>";

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
  die "Bio::Genex::ControlledVocab::get_all_objects:\nSQL=<$sql>,\nDBI=<$DBI::errstr>" 
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
    croak("Bio::Genex::ControlledVocab::get_objects called with no ID's, perhaps you meant to use Bio::Genex::ControlledVocab::get_all_objects
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
    die "Bio::Genex::ControlledVocab::initialize: $DBI::errstr" if $dbh->err;
  
    # if there was a problem, return an error to new(), so that 
    # new will return undef to the calling function
    if ($count < 1) {
      warn("Bio::Genex::ControlledVocab::initialize: no DB entries for id: $id");
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
                    COLUMNS=>['term_string', 'description'],
                    FROM=>[$self->table_name()],
                    WHERE=>$self->pkey_name() . " = '$pkey'",
                              );
  my $sth = $dbh->prepare($sql) || die "Bio::Genex::ControlledVocab::initialize: $DBI::errstr";
  $sth->execute() || die "Bio::Genex::ControlledVocab::initialize: $DBI::errstr";

  # sanity check to see if bogus id
  my $ref = $sth->fetchrow_hashref();
  die "ControlledVocab: ", $self->pkey_name(), " $pkey, not in DB"
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

Bio::Genex::ControlledVocab - Methods for processing data from the GeneX DB
 table: ControlledVocab

=head1 SYNOPSIS

  use Bio::Genex::ControlledVocab;

  # instantiating an instance
  my $ControlledVocab = Bio::Genex::ControlledVocab->new(id=>47);

  # retrieve data from the DB for all columns
  $ControlledVocab->fetch();

  # creating an instance, without pre-fetching all columns
  my $ControlledVocab = new Bio::Genex::ControlledVocab(id=>47);

  # creating an instance with pre-fetched data
  my $ControlledVocab = new Bio::Genex::ControlledVocab(id=>47, 'fetch_all'=>1);

  # retrieving multiple instances via primary keys
  my @objects = Bio::Genex::ControlledVocab->get_objects(23,57,98)


  # retrieving all instances from a table
  my @objects = Bio::Genex::ControlledVocab->get_all_objects();

  # retrieving the primary key for an object, generically
  my $primary_key = $ControlledVocab->id();

  # or specifically
  my $term_string_val = $ControlledVocab->term_string();

  # retreving other DB column attributes
  my $description_val = $ControlledVocab->description();
  $ControlledVocab->description($value);


=head1 DESCRIPTION

Each Genex class has a one to one correspondence with a GeneX DB table
of the same name (I<i.e.> the corresponding table for Bio::Genex::ControlledVocab is
ControlledVocab).


Most applications will first create an instance of Bio::Genex::ControlledVocab
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
Bio::Genex::ControlledVocab can access: I<raw> foreign key attributes,
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

Class Bio::Genex::ControlledVocab defines the following utility variables for assisting
programmers to access the ControlledVocab table.

=over 4

=item $Bio::Genex::ControlledVocab::LIMIT

If defined, $LIMIT will set a limit on any select statements that can
return multiple instances of this class (for example C<get_objects()>
or any call to a C<ONE_TO_MANY> or C<LOOKUP_TABLE> foreign key
accessor method).


=item $Bio::Genex::ControlledVocab::USE_CACHE

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

  my $ControlledVocab = Bio::Genex::ControlledVocab->new(id=>47);
  my $val = $ControlledVocab->term_string();

The attribute's value is then cached in the object so any further calls
to that attribute's getter method do not trigger a DB query.

B<NOTE>: Methods may still return C<undef> if their value in
the DB is C<NULL>.


=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Bio::Genex::ControlledVocab->methodname() syntax.

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
linking table class. For Bio::Genex::ControlledVocab it returns 0, since it is
I<not> a linking table class.

=item pkey_name()

This method returns the name of the column which is used as the
primary key for this DB table. This method only exists for non-linking
table classes, and for Bio::Genex::ControlledVocab it returns the value 'term_string';


=item table_name()

Returns the name of the DB table represented by this class. For
Bio::Genex::ControlledVocab it returns 'ControlledVocab';

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
for the ControlledVocab table.

=item column_names()

This method returns an array ref which holds the names of all the
columns in table ControlledVocab.


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


=item insert_db($dbh)

This method inserts the data for the object into the database
specified by the DB handle $dbh. To use this method, create a blank
object with C<new()>, set the attributes that you want, and then call
C<insert_db()>.

  my $dbh = Bio::Genex::current_connection(USER=>$SU_USERNAME,
                                      PASSWORD=>$SU_PASSWORD);
  my ControlledVocab = Bio::Genex::ControlledVocab->new();
  ControlledVocab->description('some_value');
  ControlledVocab->insert_db($dbh);

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
  my ControlledVocab = Bio::Genex::ControlledVocab->new(id=>43);
  ControlledVocab->description('some_value');
  ControlledVocab->update_db($dbh);

B<NOTE:> You must log into the DB with a user/password that has INSERT
priveleges in the DB, otherwise you will get a DBI error.

B<NOTE:> Any modification of the primary key value will be discarded
('term_string' for module Bio::Genex::ControlledVocab).

=item get_objects(@id_list)

=item get_all_objects()

=item get_objects({column=>'col_name',value=>'val'})

This method is used to retrieve multiple instances of class Bio::Genex::ControlledVocab
simultaneously. There are three different ways to invoke this method.

By passing in an C<@id_list>, get_objects() uses each element of the
list as a primary key for the ControlledVocab table and returns a single
instance for each entry.

B<WARNING>: Passing incorrect id values to C<get_objects()> will cause
a warning from C<Bio::Genex::ControlledVocab::initialize()>. Objects will be
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
instance of class Bio::Genex::ControlledVocab.

=over 4


=item fetch()

This method triggers a DB query to retrieve B<ALL> columns from the DB
associated with this object.


=back



B<WARNING>: methods other than those listed here are for internal use
only and are subject to change without notice. Use them at your own
risk.


=head1 ATTRIBUTE METHODS

These are the setter and getter methods for attributes in class
Bio::Genex::ControlledVocab.

B<NOTE>: To use the getter methods, you may either invoke the
C<fetch()> method to retrieve all the values for an object, or else
rely on L<delayed fetching|/DELAYED_FETCH> to retrieve the attributes
as needed.

=over 4


=item id()

C<id()> is a special attribute method that is common to all the Genex
classes. This method returns the primary key of the given instance
(and for class Bio::Genex::ControlledVocab it is synonomous with the
C<term_string()>method). The C<id()> method can be useful in writing
generic methods because it avoids having to know the name of the
primary key column. 

=item term_string()

This is the primary key attribute for Bio::Genex::ControlledVocab. It has no setter method. 


=item $value = description();

=item description($value);

Methods for the description attribute.


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

on Mon Feb  5 21:24:01 2001 by /home/jasons/work/GeneX-Server/Genex/scripts/create_genex_class.pl --dir=/home/jasons/work/GeneX-Server/Genex --target=ControlledVocab --pkey=term_string --controlled=AL_Coating --controlled=AL_DefaultSpotConcUnits --controlled=AL_TechnologyType --controlled=AL_Medium --controlled=AL_IdentifierCode --controlled=ALS_SpotType --controlled=AM_EquationType --controlled=AM_SpotMeasurementUnits --controlled=AM_Type --controlled=ContactType --controlled=EF_MajorCategory --controlled=EF_MinorCategory --controlled=ES_QuantitySeriesType --controlled=ES_TreatmentType --controlled=HS_ThresholdType --controlled=PRT_Type --controlled=SCN_ModelDescription --controlled=SMP_AgeUnits --controlled=SMP_DevelopmentStageName --controlled=SMP_DevelopmentStageUnits --controlled=SMP_GeneticStatus --controlled=SMP_OrganismIntactness --controlled=SMP_OrganType --controlled=SMP_PrimaryCellType --controlled=SMP_SexMatingType --controlled=SMP_TissueType --controlled=SPC_GeneralClassification --controlled=SPC_CellStructure --controlled=SPT_ModelDescription --controlled=SW_Name --controlled=SW_Type --controlled=USF_Type

=head1 AUTHOR

Jason E. Stewart (jes@ncgr.org)

=head1 SEE ALSO

perl(1).

=cut

##############################
#
# Bio::Genex::AL_Coating
#
##############################
package Bio::Genex::AL_Coating;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'AL_Coating';}

##############################
#
# Bio::Genex::AL_DefaultSpotConcUnits
#
##############################
package Bio::Genex::AL_DefaultSpotConcUnits;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'AL_DefaultSpotConcUnits';}

##############################
#
# Bio::Genex::AL_TechnologyType
#
##############################
package Bio::Genex::AL_TechnologyType;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'AL_TechnologyType';}

##############################
#
# Bio::Genex::AL_Medium
#
##############################
package Bio::Genex::AL_Medium;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'AL_Medium';}

##############################
#
# Bio::Genex::AL_IdentifierCode
#
##############################
package Bio::Genex::AL_IdentifierCode;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'AL_IdentifierCode';}

##############################
#
# Bio::Genex::ALS_SpotType
#
##############################
package Bio::Genex::ALS_SpotType;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'ALS_SpotType';}

##############################
#
# Bio::Genex::AM_EquationType
#
##############################
package Bio::Genex::AM_EquationType;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'AM_EquationType';}

##############################
#
# Bio::Genex::AM_SpotMeasurementUnits
#
##############################
package Bio::Genex::AM_SpotMeasurementUnits;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'AM_SpotMeasurementUnits';}

##############################
#
# Bio::Genex::AM_Type
#
##############################
package Bio::Genex::AM_Type;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'AM_Type';}

##############################
#
# Bio::Genex::ContactType
#
##############################
package Bio::Genex::ContactType;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'ContactType';}

##############################
#
# Bio::Genex::EF_MajorCategory
#
##############################
package Bio::Genex::EF_MajorCategory;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'EF_MajorCategory';}

##############################
#
# Bio::Genex::EF_MinorCategory
#
##############################
package Bio::Genex::EF_MinorCategory;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'EF_MinorCategory';}

##############################
#
# Bio::Genex::ES_QuantitySeriesType
#
##############################
package Bio::Genex::ES_QuantitySeriesType;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'ES_QuantitySeriesType';}

##############################
#
# Bio::Genex::ES_TreatmentType
#
##############################
package Bio::Genex::ES_TreatmentType;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'ES_TreatmentType';}

##############################
#
# Bio::Genex::HS_ThresholdType
#
##############################
package Bio::Genex::HS_ThresholdType;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'HS_ThresholdType';}

##############################
#
# Bio::Genex::PRT_Type
#
##############################
package Bio::Genex::PRT_Type;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'PRT_Type';}

##############################
#
# Bio::Genex::SCN_ModelDescription
#
##############################
package Bio::Genex::SCN_ModelDescription;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'SCN_ModelDescription';}

##############################
#
# Bio::Genex::SMP_AgeUnits
#
##############################
package Bio::Genex::SMP_AgeUnits;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'SMP_AgeUnits';}

##############################
#
# Bio::Genex::SMP_DevelopmentStageName
#
##############################
package Bio::Genex::SMP_DevelopmentStageName;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'SMP_DevelopmentStageName';}

##############################
#
# Bio::Genex::SMP_DevelopmentStageUnits
#
##############################
package Bio::Genex::SMP_DevelopmentStageUnits;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'SMP_DevelopmentStageUnits';}

##############################
#
# Bio::Genex::SMP_GeneticStatus
#
##############################
package Bio::Genex::SMP_GeneticStatus;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'SMP_GeneticStatus';}

##############################
#
# Bio::Genex::SMP_OrganismIntactness
#
##############################
package Bio::Genex::SMP_OrganismIntactness;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'SMP_OrganismIntactness';}

##############################
#
# Bio::Genex::SMP_OrganType
#
##############################
package Bio::Genex::SMP_OrganType;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'SMP_OrganType';}

##############################
#
# Bio::Genex::SMP_PrimaryCellType
#
##############################
package Bio::Genex::SMP_PrimaryCellType;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'SMP_PrimaryCellType';}

##############################
#
# Bio::Genex::SMP_SexMatingType
#
##############################
package Bio::Genex::SMP_SexMatingType;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'SMP_SexMatingType';}

##############################
#
# Bio::Genex::SMP_TissueType
#
##############################
package Bio::Genex::SMP_TissueType;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'SMP_TissueType';}

##############################
#
# Bio::Genex::SPC_GeneralClassification
#
##############################
package Bio::Genex::SPC_GeneralClassification;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'SPC_GeneralClassification';}

##############################
#
# Bio::Genex::SPC_CellStructure
#
##############################
package Bio::Genex::SPC_CellStructure;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'SPC_CellStructure';}

##############################
#
# Bio::Genex::SPT_ModelDescription
#
##############################
package Bio::Genex::SPT_ModelDescription;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'SPT_ModelDescription';}

##############################
#
# Bio::Genex::SW_Name
#
##############################
package Bio::Genex::SW_Name;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'SW_Name';}

##############################
#
# Bio::Genex::SW_Type
#
##############################
package Bio::Genex::SW_Type;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'SW_Type';}

##############################
#
# Bio::Genex::USF_Type
#
##############################
package Bio::Genex::USF_Type;

use strict;
use vars qw(@ISA);

@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return 'USF_Type';}

1;
