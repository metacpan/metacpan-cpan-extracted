package DBIx::DataLookup;

use 5.006;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DataLookup ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( ':all' => [ qw() ],
		     ':default' => [ qw(add_key_mapping get get_hashref) ]);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{':default'} } );

our @EXPORT = @{ $EXPORT_TAGS{':default'} };

our $VERSION = '0.02';

# PLAN:
# Instantiates an object that will store database data
# from a single table (or multiple for that matter, depending
# on the kind of SQL statement used to grab that data)
# in an internal specially arranged structure to facilitate
# quick key value lookup machanism.
# 
# example:
# statement = "select col1, col2, col3 from table foobar"
# fields = qw(col1 col2 col3)
# keys = qw(col2)
#
# if return data is:
# 
# col1_val1, col2_val1, col3_val1 # record 1
# col1_val2, col2_val2, col3_val2 # record 2
# col1_val3, col2_val3, col3_val3 # record 3
#
# Data will be structured as follows:
# %table = 
# (
#  fields => {
#            'col1' => 0,
#            'col2' => 1,
#            'col3' => 2,
#            }
#  records => [
#              ['col1_val1','col2_val1','col3_val1'], # record 1 
#              ['col1_val2','col2_val2','col3_val2'], # record 2
#              ['col1_val3','col2_val3','col3_val3'], # record 3
#             ]
#  record_keys => {
#           # col1 serves as key
#           col1 => {
#                    # key field value => list of matching records
#                    col2_val1 => [0],
#                    col2_val2 => [1],
#                    col2_val3 => [2],
#                   },
#  } 
# )
#
# So, to find a record by a value of col1, you'd have to do this:
#                     name of a key field --\
# $table{records}[$table_data{record_keys}{col1}{'col2_val2'}][$table_data{fields}{col3}]
#
# Which is equivalent to this SQL:
#
# select col3 from table foobar where col1 = 'col2_val2';
#
sub new {
  my $pkg = shift;
  my $self; { my %hash; $self = bless(\%hash, $pkg); }
  
  my (%vars) = @_;
  
  my $ar_keys;
  if (exists $vars{keys}) {
    if (ref $vars{keys} eq "ARRAY") {
      @{$ar_keys} = map {uc($_)} @{$vars{keys}};
    } 
    elsif (ref $vars{keys} eq "SCALAR") {
      $ar_keys = $vars{keys};
    }
  }

  my $statement= $vars{statement};
  my $params_aref = $vars{params};

  my $dbh = $vars{dbh};
  my $sth = $dbh->prepare($statement);
  $sth->execute(@$params_aref) or die $sth->errstr;

  # key field(s) (will allow easy hash key lookup).
  # use the first field by default.
  my $ar_fields = $sth->{NAME};

  # first field as key by default.
  $ar_keys ||= [$ar_fields->[0]]; 

  my $i = 0;
  %{$self->{table}{fields}} = map {$_ => $i++} @$ar_fields;  

  while (my @row = $sth->fetchrow_array()) {
      $self->add_record($ar_keys, [@row]);        
  }
  
  return $self;
}

#
# add a record
#
# $rec : reference to record array (all field values)
#        Care should be taken to make sure that
#        field values are arranged in proper order
#        here to match the original order in SQL
#        that was used to build data view (table data).
#
sub add_record {
    my ($self, $ar_keys, $ar_rec) = @_;
    
    # store in records hash
    push @{$self->{table}{records}}, $ar_rec;
    my $record_indx = scalar(@{$self->{table}{records}}) - 1;

    foreach my $key_field (@$ar_keys) {
	my $key_val = $ar_rec->[$self->{table}{fields}{$key_field}];
	# create key field mapping 
	push @{$self->{table}{record_keys}{$key_field}{$key_val}}, $record_indx;
    }
}

#
# maps given key to a record.
# Usually done to add new keys that would
# link to existing records.
#
# $key_field : key field name to map
# $key_value : new key value
# $map_to_value : existing key value
#
# returns: undef if mapping failed (e.g. no record to map to).
sub add_key_mapping {
    my ($self, $key_field, $key_value, $map_to_value) = @_;

    $key_field = uc($key_field);

#    $DB::single = 1;
    # retrieve matched record indexes
    my $rec_indxs = $self->_find_record_indxs($key_field, $key_value);    

    return unless ($rec_indxs);

    for my $rec_indx (@$rec_indxs) {
	# add mapping..
	push @{$self->{table}{record_keys}{$key_field}{$map_to_value}}, $rec_indx;
    }
}

#
# returns list of records in the table that
# matched key value. Each record is represented
# by an array of values.
# 
# Note: actual records are not being copied here.
#       Therefore, if user chooses to update
#       a record field value, he/she will be 
#       modifying a record field value stored
#       in this object's table.
#
sub get {
  my ($self, $key_field, $key_value) = @_;
  my $rec_num = $self->_find_record_indxs($key_field, $key_value);
  return ($rec_num) ? @{$self->{table}{records}}[@$rec_num] : ();
}

#
# get list of references to matched records represented
# as hashes. 
#
sub get_hashref {
  my ($self, $key_field, $key_value) = @_;
  my $rec_num = $self->_find_record_indxs($key_field, $key_value);

  return unless ($rec_num);

  # note: $self->{table}{records} is array ref therefore,
  # @{$self->{table}{records}}[@$rec_num] returns one or
  # more of such array refs (say, if 1 key matched a few 
  # records). 
  my @records_arrayrefs = @{$self->{table}{records}}[@$rec_num];

  my @found_records;
  for my $rec (@records_arrayrefs) {
      # build table record hash (keys -> column names)
      my %rec_hash;
      $rec_hash{$_} = $rec->[$self->{table}{fields}{$_}] for (keys %{$self->{table}{fields}});
      push(@found_records, \%rec_hash);
  }

  # return reference to the new hash struct.
  return \@found_records;
}

# returns reference to list of 
# record indexes which contain the key(s)
# $key_value may be an array ref containing
# possible keys to compare against.
sub _find_record_indxs {
  my ($self, $key_field, $key_value) = @_;

  # return if either of the two required parameters are
  # not specified.
  return unless (defined $key_field && defined $key_value);

  my $table = $self->{table};    
  $key_field = uc($key_field);
  return unless exists $table->{record_keys}{$key_field};

  my $keys = (ref $key_value eq "ARRAY") ? $key_value : [$key_value];

  my $rec_num;  
  foreach (@$keys) {
      if (exists $table->{record_keys}{$key_field}{$_}) {
	  return $table->{record_keys}{$key_field}{$_}; # ok, found!
      }      
  }
  
  return; # return undef (ak'a 'empty array' or undef based on context)
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=pod

=head1 NAME

DataLookup - Perl extension for database view lookup table.

=head1 SYNOPSIS

use DataLookup;
1. Create a DBIx::DataLookup object:

 my $country_table = new DBIx::DataLookup(
                   dbh => $dbh,
                   statement => qq{ select countrycode countryname from countries },
                   );

2. Lookup records with matching 'countrycode' field:

 my $country_rec = $country_table->get_hashref(countrycode => 'USA');
 print "Country name: " . $country_rec->[0]{COUNTRYNAME} . "\n";


Similarly, you may create DataLookup objects to allow you lookup records by multiple keys.
Here's an example of just how you could do this:

1. Again, create a DBIx::DataLookup object, but a little more complex than the one before:

 #
 # Note:  '. . .' denotes SQL expression of any complexity you wish.
 #
 my $country_table = new DBIx::DataLookup(
                   dbh => $dbh,
                   statement => qq{ select provname, provcode, countryname, countrycode
                                    from . . .
                                    where . . . },
                   keys => [qw(provcode countrycode)], # lookup keys
                   );

2. (a) Lookup records with matching provcode (Province code):

 my $prov_rec = $country_table->get_hashref(provcode => 'BC');
 print "First province name: " . $prov_rec->[0]{PROVNAME} . "\n";

2. (b) Find all provinces (or states) that belong to specified country:

 my $prov_rec = $country_table->get_hashref(countrycode => 'USA');

 foreach (@$prov_rec) {
   # $_ is a HASHREF to a hash representing 
   # a matched record.
 }

=head1 DESCRIPTION

Remotely similar to DBIx::Cache but is very simpler and
serves narrower purpose.  This module allows you to both cache
records pulled by an SQL statement from a database in the memory
as well as look them up later at any time during execution of your script.

This also speeds up access to your data at run-time and subsequently reduces 
load on the database.

For example, in your scripts, you could simply aggregate every SQL statement 
inside a hash in a config file and use them later to initialize a number of 
DBIx::DataLookup objects. Later in the code, you would simply invoke the get_hashref()
method of your DBIx::DataLookup object(s) to retrieve records matching certain key 
values. 

This module also supports alternative key mapping, which is not offered by any 
other module.  A user of this module may add alternative key mappings at run-time
to be able to link certain records with specific keys etc. For example, if you have to
deal with data supplied to you by various providers (such as news/weather syndicates etc),
there's a chance for minor irregularities in otherwise similar data (say, two vendors
use different identification codes for one theater ...)  So, when you are talking of only a dozen
(or fewer) such differing keys, key mapping offered by this module becomes quite handy.

=head2 Methods

=over 4

=item B<new(%vars)>

 my $lookup_table = new DBIx::DataLookup(dbh => reference to a database handle, 
                                         statement => SQL statement, 
                                         [keys => reference to an array of query key fields);

This constructor will create a new data lookup object for any data 
retrieved by the 'SQL statement' from a data source which the 'dbh'
database handle object was created for.  By default, the 'keys' 
parameter may be omitted in which case the first field of the 'SQL 
query' will be used as the 'lookup' field (you may look up data
only via that field's values).
 
For example, 

 my $employee_table = new DBIx::DataLookup(dbh => $dbh,
					 statement => qq{ select first_name, last_name, phone
							  from employee
							  where type = 'temp' });


Or, you may also explicitly specify a list of keys to be used:

 my $employee_table = new DBIx::DataLookup(dbh => $dbh,
					 statement => qq{ select first_name, last_name, phone
							  from employee
							  where type = 'temp' }
                                         keys => ['last_name','phone']); 


=item B<add_key_mapping($key_field, $key_value, $map_to_value)>

$key_field    -- name of a key field.
$key_value    -- new value for this key field.
$map_to_value -- existing value of this key field.

Maps new key field value to existing key field value.  
This is useful for associating additional key values 
with existing records during run-time.  

Example,

 $country_table->add_key_mapping('countryname','ENGLAND','United Kingdom');


=item B<get($key_field, $key_value)>

$key_field -- name of a key field.
$key_value -- value of the key field.

Returns one or more record(s) with matching key field
value.  Each record is represented by an array of values.
Here, values are ordered similarly to how the corresponding
fields appear in the 'SQL statement' that was used
in the new().


=item B<get_hashref($key_field, $key_value)>

Similar to get() with the only disctinction that
instead of returning an array of field values
for each matched record, this method will return
a hash structure where keys are field names,
and values are their respective values.


=head1 TODO

0. Enable lookup by multiple keys so that only records
   containing both matching keys will get returned.
   Also, could implement support for complex look up
   rules (near to what you'd get with SQL WHERE clause).

1. Add set(field => value) method to allow user to set
   a record field to a new value.

2. Add commit() ? to save data back into the database.
   Note: may have to deal with original SQL statement
         in odrer to build a proper UPDATE SQL command.

3. Write more POD!


=head1 EXPORT

:default - add_key_mapping(), get(), get_hashref()


=head1 AUTHOR

Vladimir Bogdanov E<lt>b_vlad@telus.netE<gt>


=head1 SEE ALSO

L<DBI>.

=cut


