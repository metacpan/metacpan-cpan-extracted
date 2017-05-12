package DBR::ResultSet;

use strict;
use base 'DBR::Common';

use DBR::Misc::Dummy;
use Carp;
use Scalar::Util 'weaken';
use constant ({
	       f_next      => 0,
	       f_state     => 1,
	       f_rowcache  => 2,
	       f_query     => 3,
	       f_count     => 4,
	       f_splitval  => 5,

	       stCLEAN  => 1,
	       stACTIVE => 2,
	       stMEM    => 3,

	       FIRST  => \&_first,
	       DUMMY  => bless([],'DBR::Misc::Dummy'),
	      });


sub new {
      my ( $package, $query, $splitval ) = @_;

      #the sequence of this MUST line up with the fields above
      return bless( [
		     FIRST,    # next
		     stCLEAN,  # state
		     [],     # rowcache - placeholder
		     $query,   # query
		     undef,    # count
		     $splitval,# splitval
		     ], $package );
}


sub next { $_[0][ f_next ]->( $_[0] ) }

sub dump{
      my $self = shift;
      my @fields = map { split(/\s+/,$_) } @_;

      map { croak "invalid field '$_'" unless /^[A-Za-z0-9_\.]+$/ } @fields;


      my $code = 'while(my $rec = $self->next){ push @out, {' . "\n";

      foreach my $field ( @fields){
	    my $f = $field;
	    $f =~ s/\./->/g;
	    $code .= "'$field' => \$rec->$f,\n";
      }

      $code .= "}}";
      my @out;
      eval $code;

      die "eval returned '$@'" if $@;

      wantarray ? @out : \@out;
}

sub TO_JSON {
      my $self = shift;

      return $self->dump(
			 map { $_->name } @{ $self->[f_query]->primary_table->fields }
			);

} #Dump it all

sub reset{
      my $self = shift;

      if ($self->[f_state] == stMEM){
	    return $self->_mem_iterator; #rowcache is already full, reset the mem iterator
      }

      if( $self->[f_state] == stACTIVE ){
	    $self->[f_query]->reset; # calls finish
	    $self->[f_rowcache] = []; #not sure if this is necessary or not
	    $self->[f_state] = stCLEAN;
	    $self->[f_next]  = FIRST;
      }

      return 1;
}

sub _first{
      my $self = shift;

      $self->_execute();
      return $self->next;
}

sub _execute{
      my $self = shift;

      $self->[f_state] == stCLEAN or croak "Cannot call _execute unless in a clean state";

      if( defined( $self->[f_splitval] ) ){

	    my $rows = $self->[f_rowcache] = $self->[f_query]->fetch_segment( $self->[f_splitval] ); # Query handles the sth
	    $self->_mem_iterator;

      }else{

	    $self->_db_iterator;

      }

      return 1;
}

sub _db_iterator{
      my $self = shift;


      my $record = $self->[f_query]->get_record_obj;
      my $class  = $record->class;

      my $sth    =  $self->[f_query]->run;

      defined( my $rv = $sth->execute ) or confess 'failed to execute statement (' . $sth->errstr. ')';

      $self->[f_state] = stACTIVE;

      if( $self->[f_query]->instance->getconn->can_trust_execute_rowcount ){ # HERE - yuck... assumes this is same connection as the sth
	    $self->[f_count] = $rv + 0;
	    $self->[f_query]->_logDebug3('ROWS: ' . ($rv + 0));
      }

     

      # IMPORTANT NOTE: circular reference hazard
      weaken ($self); # Weaken the refcount

      my $endsub = sub {
	    defined($self) or return DUMMY; # technically this could be out of scope because it's a weak ref

	    $self->[f_count] ||= $sth->rows || 0;
	    $self->[f_next]  = FIRST;
	    $self->[f_state] = stCLEAN; # If we get here, then we hit the end, and no ->finish is required

	    return DUMMY; # evaluates to false
      };

      my $buddy;
      my $rows  = [];
      my $commonref;
      my $getchunk = sub {
	    $rows = $sth->fetchall_arrayref(undef,1000) || return undef; # if cache is empty, fetch more
	    
	    $commonref = [ @$rows ];
	    map {weaken $_} @$commonref;
	    $buddy = [ $commonref, $record ]; # buddy ref must contain the record object just to keep it in scope.
	    
	    return shift @$rows;
      };
      # use a closure to reduce hash lookups
      # It's very important that this closure is fast.
      # This one routine has more of an effect on speed than anything else in the rest of the code

      $self->[f_next] = sub {
	    bless(
		  (
		   [
		   (
		    shift(@$rows) || $getchunk->() || return $endsub->()
		   ),
		    $buddy
		   ]
		  ),
		  $class
		 );
      };

      return 1;

}

sub _mem_iterator{
      my $self = shift;

      my $record = $self->[f_query]->get_record_obj;
      my $class  = $record->class;

      my $buddy  = [ $self->[f_rowcache], $record ]; # buddy ref must contain the record object just to keep it in scope.

      my $rows  = $self->[f_rowcache];
      my $ct = 0;

      # use a closure to reduce hash lookups
      # It's very important that this closure is fast.
      # This one routine has more of an effect on speed than anything else in the rest of the code
      $self->[f_next] = sub {
	    bless( (
		    [
		     ($rows->[$ct++] or $ct = 0 or return DUMMY ),
		     $buddy # buddy object comes along for the ride - to keep my recmaker in scope
		    ]
		   ),	$class );
      };

      $self->[f_state] = stMEM;
      $self->[f_count] = @$rows;
      return 1;

}

sub _fetch_all{
      my $self = shift;

      if( $self->[f_state] == stCLEAN ){
	    $self->_execute;
      }

      if( $self->[f_state] == stMEM ){ # This should cover split queries

	    return $self->[f_rowcache];

      }else{ # Must be stACTIVE

	    my $sth = $self->[f_query]->run; # just gets the sth if it's already been run

	    my $rows = $self->[f_rowcache] = $sth->fetchall_arrayref();

	    $self->_mem_iterator(); # everything is in memory now, so use _mem_iterator

	    return $rows;
      }
}

###################################################
### Utility #######################################
###################################################

sub count{
      my $self = shift;
      return $self->[f_count] if defined $self->[f_count];

      if( defined $self->[f_splitval] ){ # run automatically if we are a split query
	    $self->_execute();
	    return $self->[f_count];
      }

      my $cquery = $self->[f_query]->transpose('Count');

      return $self->[f_count] = $cquery->run;

      # Consider profiling min/max/avg rows returned for the scope in question
      # IF max / avg  is < 1000 just fetch all rows instead of executing another query

}


sub set {
       my $self = shift;
       my %params = @_;

       my $tables = $self->[f_query]->tables;
       my $table = $tables->[0]; # only the primary table is supported
       my $alias = $table->alias;

       my @sets;
       foreach my $name ( keys %params ){
	     my $field = $table->get_field( $name ) or croak "Invalid field $name";
	     $field->alias( $alias ) if $alias;

	     $field->is_readonly && croak ("Field $name is readonly");

	     my $value = $field->makevalue( $params{ $name } );

	     $value->count == 1 or croak("Field $name allows only a single value");

	     my $setobj   = DBR::Query::Part::Set->new( $field, $value ) or return $self->_error('failed to create set object');

	     push @sets, $setobj;
       };

       scalar(@sets) > 0 or croak('Must specify at least one field to set');

       my $update = $self->[f_query]->transpose( 'Update',
						 sets => \@sets
					       );
       return $update->run;

}

sub where {
       my $self = shift;

       return DBR::ResultSet->new(
				  $self->[f_query]->child_query( \@_ ), # Where clause
				  $self->[f_splitval],
				 );
}

sub delete { croak "Mass delete is not allowed. No cookie for you!" }

# Dunno if I like this
sub each {
      my $self    = shift;
      my $coderef = shift;
      my $r;
      $coderef->($r) while ($r = $self->[f_next]->( $self ) );

      return 1;

}

# get all instances of a field or fields from the resultset
# Kind of a flimsy way to do this, but it's lightweight
sub values {
      my $self = shift;
      my @fieldnames = grep { /^[A-Za-z0-9_.]+$/ } map { split(/\s+/,$_) }  @_;

      scalar(@fieldnames) or croak('Must provide a list of field names');

      my $rows = $self->_fetch_all;

      return wantarray?():[] unless $self->count > 0;

      my @parts;
      foreach my $fieldname (@fieldnames){
	    $fieldname =~ s/\./->/g; # kind of a hack, but it works
	    push @parts , "\$_[0]->$fieldname";
      }

      my $code;
      if(scalar(@fieldnames) > 1){
	    $code = ' [  ' . join(', ', @parts) . ' ]';
      }else{
	    $code = $parts[0];
      }

      $code = 'sub{ push @output, ' . $code . ' }';

      $self->[f_query]->_logDebug3($code);

      my @output;
      my $sub = eval $code;
      confess "values failed ($@)" if $@;

      $self->each($sub) or confess "Failed to each";

      return wantarray?(@output):\@output;
}

sub hashmap_multi { shift->_lookuphash('multi', @_) }
sub hashmap_single{ shift->_lookuphash('single',@_) }

sub _lookuphash{
      my $self = shift;
      my $mode = shift;
      my @fieldnames = map { split(/\s+/,$_) } @_;

      scalar(@fieldnames) or croak('Must provide a list of field names');

      my $rows = $self->_fetch_all;

      return {} unless $self->count > 0;

      my $record = $self->[f_query]->get_record_obj;
      my $class  = $record->class;
      my $buddy  = [ $self->[f_rowcache], $record ]; # buddy ref must contain the record object just to keep it in scope.

      my $code;
      foreach my $fieldname (@fieldnames){
	    my @parts = split(/\.|\->/,$fieldname);
	    map {croak "Invalid fieldname part '$_'" unless /^[A-Za-z0-9_-]+$/} @parts;

	    $fieldname = join('->',@parts);

	    $code .= "{ \$_->$fieldname }";
      }
      my $part = ' map {  bless([$_,$buddy],$class)  } @{$rows}';

      if($mode eq 'multi'){
	    $code = 'map {  push @{ $lookup' . $code . ' }, $_ }' . $part;
      }else{
	    $code = 'map {  $lookup' . $code . ' = $_ }' . $part;
      }
      $self->[f_query]->_logDebug3($code);

      my %lookup;
      eval $code;
      croak "hashmap_$mode failed ($@)" if $@;

      return \%lookup;
}

1;
