package DBR::Record::Helper;

use strict;
use base 'DBR::Common';
use Carp;
use DBR::Query::Part;
use DBR::Query::Select;
use DBR::Query::Update;
use DBR::Query::Delete;
use DBR::ResultSet;
use DBR::ResultSet::Empty;
use DBR::Misc::Dummy;

# we can get away with making these once for all time
use constant ({
	       EMPTY => bless( [], 'DBR::ResultSet::Empty'),
	       DUMMY => bless( [], 'DBR::Misc::Dummy'),
	      });
sub new {
      my( $package ) = shift;
      my %params = @_;
      my $self = {
		  session  => $params{session},
		  instance => $params{instance},
		  tablemap => $params{tablemap},
		  flookup  => $params{flookup},
		  pkmap    => $params{pkmap},
		  scope    => $params{scope},
		  lastidx  => $params{lastidx},
		 };

      bless( $self, $package ); # BS object

      $self->{session}  or return $self->_error('session is required');
      $self->{instance} or return $self->_error('instance is required');
      $self->{scope}    or return $self->_error('scope is required');

      $self->{tablemap} or return $self->_error('tablemap is required');
      $self->{pkmap}    or return $self->_error('pkmap is required');           # X
      $self->{flookup}  or return $self->_error('flookup is required');         # X
      defined($self->{lastidx}) or return $self->_error('lastidx is required');

      return $self;
}

sub set{
      my $self = shift;
      my $record = shift;
      my %params = @_;

      my %sets;
      foreach my $fieldname (keys %params){
	    my $field = $self->{flookup}->{$fieldname} or return $self->_error("$fieldname is not a valid field");
	    $field->is_readonly && return $self->_error("Field $fieldname is readonly");

	    my $setvalue = $field->makevalue($params{$fieldname}) or return $self->_error('failed to create setvalue object');
	    $setvalue->count == 1 or return $self->_error("Field ${\$field->name} allows only a single value");

	    my $setobj   = DBR::Query::Part::Set->new( $field, $setvalue ) or return $self->_error('failed to create set object');

	    push @{$sets{$field->table_id}}, $setobj;
      }
      my $ct = scalar(keys %sets);

      return $self->_error('Must specify at least one field to set') unless $ct > 0;

      my $dbrh;
      if($ct > 1){
	    # create a new DBRH here to ensure proper transactional handling
	    $dbrh = $self->{instance}->connect or return $self->_error('failed to connect');
	    $dbrh->begin;
      }

      foreach my $table_id (keys %sets){
	    $self->_set($record, $table_id, $sets{$table_id}) or return $self->_error('failed to set');
      }

      $dbrh->commit if $ct > 1;

      return 1;
}

# set a field REGARDLESS of whether it was prefetched or not
sub setfield{
      my $self = shift;
      my $record = shift;
      my $field = shift;
      my $value = shift;

      my $setvalue = $field->makevalue($value) or return $self->_error('failed to create value object');
      $setvalue->count == 1 or return $self->_error("Value of ${\$field->name} must have only a single value");

      my $setobj   = DBR::Query::Part::Set->new( $field, $setvalue ) or return $self->_error('failed to create set object');

      return $self->_set($record, $field->table_id, [$setobj]);
}

sub _set{
      my $self = shift;
      my $record = shift;
      my $table_id = shift;
      my $sets = shift;

      my ($outwhere,$table) = $self->_pk_where($record,$table_id) or return $self->_error('failed to create where tree');

      my $query = DBR::Query::Update->new(
					  session  => $self->{session},
					  instance => $self->{instance},
					  tables   => $table,
					  where    => $outwhere,
					  sets     => $sets
					 ) or return $self->_error('failed to create Query object');

      my $rv = $query->run() or return $self->_error('failed to execute');

      foreach my $set (@$sets){
	    $self->_setlocalval($record, $set->field, $set->value->raw->[0]);
      }

      return $rv;
}

sub delete{
       my $self = shift;
       my $record = shift;

       return $self->_error('Cannot call delete on join record')
	 if scalar(keys %{$self->{tablemap}}) > 1;

       my ($table_id) = keys %{$self->{tablemap}};

       my ($outwhere,$table) = $self->_pk_where($record,$table_id) or return $self->_error('failed to create where tree');

       my $query = DBR::Query::Delete->new(
					   session  => $self->{session},
					   instance => $self->{instance},
					   tables   => $table,
					   where    => $outwhere,
					  ) or return $self->_error('failed to create Query object');

       $query->run or return $self->_error('failed to execute');

       return 1;
}


# Fetch a field ONLY if it was not prefetched
sub getfield{
       my $self = shift;
       my $record = shift;
       my $field = shift;
       my $want_sref = shift;

       # Check to see if we've previously been assigned an index. if so, see if our record already has it fetched
       # This could happen if the field was not fetched in the master query, but was already fetched with getfield
       my $idx = $field->index;
       return $record->[$idx] if defined($idx) && exists($record->[$idx]);

       $self->{scope}->addfield($field) or return $self->_error('Failed to add field to scope');

       my ($outwhere,$table)  = $self->_pk_where($record,$field->table_id) or return $self->_error('failed to create where tree');

       # Because we are doing a new select, which will set the indexes on
       # its fields, we must clone the field provided by the original query
       my $newfield = $field->clone;

       my $query = DBR::Query::Select->new(
					   session  => $self->{session},
					   instance => $self->{instance},
					   tables   => $table,
					   where    => $outwhere,
					   fields   => [ $newfield ] # use the new cloned field
					  ) or return $self->_error('failed to create Query object');

       my $sth = $query->run or return $self->_error('failed to execute');

       $sth->execute() or return $self->_error('Failed to execute sth');
       my $row  = $sth->fetchrow_arrayref() or return $self->_error('Failed to fetchrow');

       my $val = $row->[ $newfield->index ];

       $self->_setlocalval($record,$field,$val);

       return $want_sref?\$val:$val; # return a scalarref if requested
}

sub getrelation{
      my $self = shift;
      my $obj = shift;
      my $relation = shift;
      my $field  = shift;

      my $record = $obj->[0];
      my $buddy  = $obj->[1];
      my $rowcache = $buddy->[0];

      my $ridx = $relation->index;
      # Check to see if this record has a cached version of the resultset
      return $record->[$ridx] if defined($ridx) && exists($record->[$ridx]); # skip the rest if we have that

      my $fidx = $field->index();
      my $val;

      my $to1 = $relation->is_to_one;                                                        # Candidate for pre-processing
      my $table    = $relation->table    or return $self->_error('Failed to fetch table'   );# Candidate for pre-processing
      my $maptable = $relation->maptable or return $self->_error('Failed to fetch maptable');# Candidate for pre-processing
      my $mapfield = $relation->mapfield or return $self->_error('Failed to fetch mapfield');# Candidate for pre-processing

      my @allvals; # For uniq-ing

      if( defined($fidx) && exists($record->[$fidx]) ){
	    $val = $record->[ $fidx ]; # My value
	    @allvals = $self->_uniq( $val, map { $_->[ $fidx ] } grep {defined} @$rowcache ); # look forward in the rowcache and add those too
      }else{
	    # I forget, I think I'm using scalar ref as a way to represent undef and still have a true rvalue *ugh*
	    my $sref = $self->getfield($record,$field, 1 ); # go fetch the value in the form of a scalarref
	    defined ($sref) or return $self->_error("failed to fetch the value of ${\ $field->name }");
	    $val = $$sref;
	    $fidx ||= $field->index;
	    confess('field object STILL does not have an index') unless defined($fidx);
	    push @allvals, $val;
      }

      my $rowcount = scalar @allvals; # Cheapest way to get a rowcount is here, before we filter

      unless($mapfield->is_nullable){ # Candidate for pre-defined global
	    @allvals = grep { defined } @allvals;
      }

      unless(scalar @allvals){
	    # no values? then for sure, the relationship for this record must be empty.
	    # Cache the emptyness so we don't have to repeat this work
	    return $self->_setlocalval( $record, $relation, $to1 ? DUMMY : EMPTY );
      }

      my $value    = $mapfield->makevalue( \@allvals );
      my $outwhere = DBR::Query::Part::Compare->new( field => $mapfield, value => $value );

      my $scope = DBR::Config::Scope->new(
					  session       => $self->{session},
					  conf_instance => $maptable->conf_instance,
					  extra_ident   => $maptable->name,
					  offset        => 2,  # because getrelation is being called indirectly, look at the scope two levels up
					 ) or return $self->_error('Failed to get calling scope');

      my $pk        = $maptable->primary_key or return $self->_error('Failed to fetch primary key');
      my $prefields = $scope->fields or return $self->_error('Failed to determine fields to retrieve');

      my %uniq;
      my @fields = grep { !$uniq{ $_->field_id }++ } ($mapfield, @$pk, @$prefields );

      my $mapinstance = $self->{instance};
      unless ( $relation->is_same_schema ){
	    $mapinstance = $maptable->schema->get_instance( $mapinstance->class ) or return $self->_error('Failed to retrieve db instance for the maptable');
      }

      $self->_logDebug2( "Relationship from instance " . $self->{instance}->guid . "->" . $mapinstance->guid );
      my $query = DBR::Query::Select->new(
					  session  => $self->{session},
					  instance => $mapinstance,
					  tables   => $maptable,
					  where    => $outwhere,
					  fields   => \@fields,
					  scope    => $scope,
					  splitfield  => $mapfield
					 ) or return $self->_error('failed to create Query object');


      if($rowcount > 1){
	    my $myresult;
	    if($to1){
		  my $resultset =  DBR::ResultSet->new( $query ) or croak('Failed to create resultset');
		  $self->_logDebug2('mapping to individual records');
		  my $resultmap = $resultset->hashmap_single(  $mapfield->name  ) or return $self->_error('failed to split resultset');

		  # look forward in the rowcache and assign the resultsets for whatever we find
		  foreach my $row (grep {defined} @$rowcache) {
			$self->_setlocalval(
					    $row,
					    $relation,
					    $resultmap->{ $row->[$fidx] } || DUMMY
					   );
		  }

		  $myresult = $resultmap->{$val} || DUMMY;

	    }else{
		  # look forward in the rowcache and assign the resultsets for whatever we find
		  foreach my $row (grep {defined} @$rowcache) {
			$self->_setlocalval($row,
					    $relation,
					    DBR::ResultSet->new( $query, $row->[$fidx] )
					   );
		  }

		  $myresult = DBR::ResultSet->new( $query, $val );
	    }

	    $self->_setlocalval($record,$relation,$myresult);

	    return $myresult;

      }else{
	    my $resultset =  DBR::ResultSet->new( $query ) or croak('Failed to create resultset');
	    my $result = $resultset;
	    if($to1){
		  $result = $resultset->next;
	    }

	    $self->_setlocalval($record,$relation,$result);

	    return $result;
      }
}

sub _pk_where{
      my $self = shift;
      my $record = shift;
      my $table_id = shift;

      my $table = $self->{tablemap}->{ $table_id } || return $self->_error('Missing table for table_id ' . $table_id );
      my $pk    = $self->{pkmap}->{ $table_id }    || return $self->_error('Missing primary key');

      my @and;
      foreach my $part (@{ $pk }){

	    my $value = $part->makevalue( $record->[ $part->index ] ) or return $self->_error('failed to create value object');
	    my $outfield = DBR::Query::Part::Compare->new( field => $part, value => $value ) or return $self->_error('failed to create compare object');

	    push @and, $outfield;
      }


      return (DBR::Query::Part::And->new(@and), $table);
}

sub _setlocalval{
      my $self   = shift;
      my $record = shift;
      my $field  = shift; # Could also be a relationship object
      my $val    = shift;

      my $idx = $field->index;
      # update the field object to give it an index if necessary
      if(!defined $idx){ #Could be 0
	    $idx = ++$self->{lastidx};
	    $field->index($idx); # so we'll have it for next time this gets accessed
      }

      # Update this record to reflect the new value
      return $record->[$idx] = $val;
}

1;
