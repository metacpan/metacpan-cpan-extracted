# the contents of this file are Copyright (c) 2004-2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Interface::DBRv1;

use strict;
use base 'DBR::Common';
use DBR::Query::Select;
use DBR::Query::Count;
use DBR::Query::Insert;
use DBR::Query::Update;
use DBR::Query::Delete;
use DBR::Config::Field::Anon;
use DBR::Config::Table::Anon;
use DBR::Query::Part;
use DBR::ResultSet;
use Carp;

sub new {
      my( $package ) = shift;
      my %params = @_;

      my $self = {
		  instance => $params{instance},
		  session   => $params{session},
		 };

      bless( $self, $package );
      return $self->_error('instance object is required') unless $self->{instance};

      return( $self );
}


###################################################
### Direct methods for DBRv1 ######################
###################################################

sub select {
      my $self   = shift;
      my %params = @_;

      my $tables = $self->_split( $params{-table} || $params{-tables} ) or
	return $self->_error("No -table[s] parameter specified");

      my $Qtables = $self->_tables($tables) or return $self->_error('tables failed');
      my @Qfields;

      if(!$params{'-count'}){
	    my $fields = $self->_split( $params{-fields} || $params{-field}) or
	      return $self->_error('No -field[s] parameter specified');

	    foreach my $field (@$fields){
		  my $Qfield = DBR::Config::Field::Anon->new(
							     session => $self->{session},
							     name   => $field
							    ) or return $self->_error('Failed to create field object');
		  push @Qfields, $Qfield;
	    }
      }

      my $where;
      if($params{-where}){
	    $where = $self->_where($params{-where});
	    return $self->_error('failed to prep where') unless defined($where);
      }

      my $limit = $params{'-limit'};
      if(defined $limit){
	    return $self->_error('invalid limit') unless $limit =~ /^\d+$/;
      }

      my $class =  'DBR::Query::' . ($params{'-count'} ? 'Count':'Select');
      my $query = $class->new(
			      instance => $self->{instance},
			      session  => $self->{session},

			      fields   => \@Qfields,
			      tables   => $Qtables,
			      where    => $where,
			      limit    => $limit,
			     ) or return $self->_error('failed to create query object');

      if ($params{-count}) {
	    return $query->run; # Returns the count directly

      } elsif ($params{-query}){
	    return $query;

      }elsif ($params{-rawsth}) {

	    my $sth = $query->run or return $self->_error('failed to run');
	    $sth->execute() or croak('failed to execute sth');

	    return $sth;

      } else {
	    if ($params{'-object'}) { # new way - hybrid
		  return  DBR::ResultSet->new( $query );
	    }

	    my $sth = $query->run;
	    $sth->execute() or croak ('failed to execute sth');

	    if ($params{-arrayref}) {
		  return $sth->fetchall_arrayref(); # ->finish is automatic
	    } elsif ($params{-keycol}) {
		  return $sth->fetchall_hashref($params{-keycol});
	    } elsif ($params{-single}) {
		  my $row = $sth->fetchrow_hashref();
		  $sth->finish;
		  return $row || 0;
	    } else {
		  return $sth->fetchall_arrayref({}); # ->finish is automatic
	    }
      }

}

sub insert {
      my $self = shift;
      my %params = @_;


      my $table = $params{-table} || $params{-insert};
      my $fields = $params{-fields};

      return $self->_error('No -table parameter specified') unless $table && $table =~ /^[A-Za-z0-9_-]+$/;
      return $self->_error('No proper -fields parameter specified') unless ref($fields) eq 'HASH';

      my $Qtable = DBR::Config::Table::Anon->new(
						 session => $self->{session},
						 name    => $table,
						) or return $self->_error('Failed to create table object');
      my @sets;
      foreach my $field (keys %$fields){
	    my $value = $fields->{$field};

	    my $fieldobj = DBR::Config::Field::Anon->new(
							 session => $self->{session},
							 name   => $field
							) or return $self->_error('Failed to create field object');

	    my $valobj = $self->_value($value) or return $self->_error('_value failed');

	    my $set = DBR::Query::Part::Set->new($fieldobj,$valobj) or return $self->_error('failed to create set object');
	    push @sets, $set;
      }

      my $query = DBR::Query::Insert->new(
					  instance => $self->{instance},
					  session  => $self->{session},
					  sets   => \@sets,
					  quiet_error => $params{-quiet} ? 1:0,
					  tables => $Qtable,
					 ) or return $self->_error('failed to create query object');

      return $query->run();

}

sub update {
      my $self = shift;
      my %params = @_;


      my $table  = $params{-table} || $params{-update};
      my $fields = $params{-fields};

      return $self->_error('No -table parameter specified') unless $table =~ /^[A-Za-z0-9_-]+$/;
      return $self->_error('No proper -fields parameter specified') unless ref($fields) eq 'HASH';

      my $Qtable = DBR::Config::Table::Anon->new(
						 session => $self->{session},
						 name    => $table,
						) or return $self->_error('Failed to create table object');
      my $where;
      if($params{-where}){
	    $where = $self->_where($params{-where}) or return $self->_error('failed to prep where');
      }else{
	    return $self->_error('-where hashref/arrayref must be specified');
      }

      my @sets;
      foreach my $field (keys %$fields){
	    my $value = $fields->{$field};

	    my $fieldobj = DBR::Config::Field::Anon->new(
							 session => $self->{session},
							 name   => $field
							) or return $self->_error('Failed to create field object');

	    my $valobj = $self->_value($value) or return $self->_error('_value failed');

	    my $set = DBR::Query::Part::Set->new($fieldobj,$valobj) or return $self->_error('failed to create set object');

	    push @sets, $set;
      }

      my $query = DBR::Query::Update->new(
					  instance => $self->{instance},
					  session  => $self->{session},
					  sets     => \@sets,
					  tables   => $Qtable,
					  where    => $where,
					  quiet_error => $params{-quiet} ? 1:0,
					 ) or return $self->_error('failed to create query object');

      return $query->run();

}
sub delete {
      my $self = shift;
      my %params = @_;


      my $table  = $params{-table} || $params{-delete};

      return $self->_error('No -table parameter specified') unless $table =~ /^[A-Za-z0-9_-]+$/;

      my $Qtable = DBR::Config::Table::Anon->new(
						 session => $self->{session},
						 name    => $table,
						) or return $self->_error('Failed to create table object');
      my $where;
      if($params{-where}){
	    $where = $self->_where($params{-where}) or return $self->_error('failed to prep where');
      }else{
	    return $self->_error('-where hashref/arrayref must be specified');
      }

      my $query = DBR::Query::Delete->new(
					  instance => $self->{instance},
					  session   => $self->{session},
					  tables   => $Qtable,
					  where    => $where,
					  quiet_error => $params{-quiet} ? 1:0
					 ) or return $self->_error('failed to create query object');

      return $query->run();

}

sub _tables{
      my $self = shift;
      my $tables = shift;

      if(ref($tables) eq 'ARRAY' and @{$tables} == 1){
	    $tables = $tables->[0]
      }

      my @Qtables;
      if(ref($tables) eq 'ARRAY'){
	    my $ct = 0;
	    foreach my $table (@{$tables}){
		  return $self->_error("Invalid table name specified ($table)") unless
		    $table =~ /^[A-Za-z][A-Za-z0-9_-]*$/;

		  return $self->_error('No more than 26 tables allowed in a join') if $ct > 25;
		  my $alias = chr(97 + $ct++); # a-z

		  my $Qtable = DBR::Config::Table::Anon->new(
							     session => $self->{session},
							     name    => $table,
							     alias   => $alias,
							    ) or return $self->_error('Failed to create table object');
		  push @Qtables, $Qtable;
	    }
      }elsif(ref($tables) eq 'HASH'){
	    foreach my $alias (keys %{$tables}){

		  return $self->_error("invalid table alias '$alias' in -table[s]") unless $alias =~ /^[A-Za-z][A-Za-z0-9_-]*$/;
		  my $table = $tables->{ $alias };
		  return $self->_error("Invalid table name specified ($table)")     unless $table =~ /^[A-Za-z][A-Za-z0-9_-]*$/;

		  my $Qtable = DBR::Config::Table::Anon->new(
							     session => $self->{session},
							     name    => $table,
							     alias   => $alias,
							    ) or return $self->_error('Failed to create table object');
		  push @Qtables, $Qtable;
	    }
      }else{
	    return $self->_error("Invalid table name specified ($tables)") unless $tables =~ /^[A-Za-z][A-Za-z0-9_-]*$/;

	    my $Qtable = DBR::Config::Table::Anon->new(
						       session => $self->{session},
						       name    => $tables,
						      ) or return $self->_error('Failed to create table object');
	    push @Qtables, $Qtable;
      }

      return \@Qtables;

}

sub _where {
      my $self = shift;
      my $param = shift;

      $param = [%{$param}] if (ref($param) eq 'HASH');
      $param = [] unless (ref($param) eq 'ARRAY');


      return 0 unless scalar(@$param); # No where parameters

      my $where;

      my @out;
      while (@{$param}) {
	    my $val1 = shift @{$param};

	    # is it an OR? (single element)
	    if (ref($val1) eq 'ARRAY') {
		  my @or;
		  foreach my $element (@{ $val1 }){
			push @or, $self->_where($element) or $self->_error('convertvals failed');
		  }

		  push @out, DBR::Query::Part::Or->new( @or );

	    } else {
		  my $key   = $val1;
		  my $value = shift @{$param};

		  if (ref($value) eq 'HASH') {
			if($value->{-table} && ($value->{-field} || $value->{-fields})){ #does it smell like a subquery?

			      my $field = DBR::Config::Field::Anon->new(
									session => $self->{session},
									name   => $key,
								       ) or return $self->_error('Failed to create field object');

			      my $compat = DBR::Interface::DBRv1->new(
								      session   => $self->{session},
								      instance => $self->{instance},
								     ) or return $self->_error('failed to create Query object');

			      my $query = $compat->select(%{$value}, -query => 1) or return $self->_error('failed to create query object');
			      return $self->_error('invalid subquery') unless $query->can_be_subquery;

			      push @out, DBR::Query::Part::Subquery->new($field, $query);

			}else{
			      my $alias = $key;

			      if(%{$value}){
				    foreach my $k (keys %{$value}) {
					  print STDERR "FOO: '$alias.$k'\n";
					  my $ret = $self->_processfield("$alias.$k", $value->{$k}) or return $self->_error('failed to process field object');
					  push @out, $ret
				    }
			      }

			}

		  } else {

			my $ret = $self->_processfield($key,$value) or return $self->_error('failed to process field object');

			push @out, $ret
		  }

	    }
      }

      if(@out > 1){
	    return DBR::Query::Part::And->new(@out);
      }else{
	    return $out[0];
      }

}

sub _processfield{
      my $self    = shift;
      my $fieldname = shift;
      my $value   = shift;

      my $field = DBR::Config::Field::Anon->new(
						session => $self->{session},
						name   => $fieldname
					       ) or return $self->_error('Failed to create fromfield object');
      my $flags;

      if (ref($value) eq 'ARRAY'){
	    $flags = $value->[0];
      }

      if ($flags && $flags =~ /j/) {	# join

	    my $tofield = DBR::Config::Field::Anon->new(
							session => $self->{session},
							name   => $value->[1]
						       ) or return $self->_error('Failed to create tofield object');

	    my $join = DBR::Query::Part::Join->new($field,$tofield)
	      or return $self->_error('failed to create join object');

	    return $join;

      } else {
	    my $is_number = 0;
	    my $operator;

            if ($flags) {
                  if ( $flags =~ /like/ ) {
                        $operator = 'like';# like
                        #return $self->_error('LIKE flag disabled without the allowquery flag') unless $self->{config}->{allowquery};
                  } elsif ( $flags =~ /!/    ) { $operator = 'not'; # Not
	          } elsif ( $flags =~ /\<\>/ ) { $operator = 'not'; $is_number = 1; # greater than less than
	          } elsif ( $flags =~ /\>=/  ) { $operator = 'ge'; $is_number = 1; # greater than eq
	          } elsif ( $flags =~ /\<=/  ) { $operator = 'le'; $is_number = 1; # less than eq
	          } elsif ( $flags =~ /\>/   ) { $operator = 'gt'; $is_number = 1; # greater than
	          } elsif ( $flags =~ /\</   ) { $operator = 'lt'; $is_number = 1; # less than
	          }
            }

	    $operator ||= 'eq';

	    my $valobj = $self->_value($value,$is_number) or return $self->_error('_value failed');

	    my $compobj = DBR::Query::Part::Compare->new(
							 field    => $field,
							 operator => $operator,
							 value    => $valobj
							) or return $self->_error('failed to create compare object');

	    return $compobj;

      }

}

sub _value {
      my $self = shift;
      my $value = shift;
      my $is_number = shift || 0;

      my $flags;
      if (ref($value) eq 'ARRAY'){
	    $value = [ @$value ]; # shallow clone
	    $flags = shift @$value;
      }

      if($flags && $flags =~ /d/){  $is_number = 1 }

      my $valobj = DBR::Query::Part::Value->new(
						is_number => $is_number,
						value     => $value,
						session    => $self->{session}
					       ) or return $self->_error('failed to create value object');
      return $valobj;

}

1;
