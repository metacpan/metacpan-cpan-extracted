package Bio::ConnectDots::ConnectorQuery;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
#use lib "/users/ywang/temp";
use Bio::ConnectDots::Util;
use Bio::ConnectDots::Connector;
use Bio::ConnectDots::Dot;
use Bio::ConnectDots::ConnectorQuery::Constraint;
use Bio::ConnectDots::ConnectorQuery::Alias;
use Bio::ConnectDots::ConnectorQuery::Join;
use Bio::ConnectDots::Parser;
use Bio::ConnectDots::ConnectorQuery::Inner;
use Bio::ConnectDots::ConnectorQuery::Outer;
use Class::AutoClass;
@ISA = qw(Class::AutoClass); # AutoClass must be first!!

@AUTO_ATTRIBUTES=qw(connectortable constraints joins
		    name2ct_alias name2cs_alias
		    _ct_aliases _cs_aliases);
@OTHER_ATTRIBUTES=qw(ct_aliases cs_aliases);
%SYNONYMS=(rods=>'joins');
%DEFAULTS=(_ct_aliases=>[],_cs_aliases=>[],
	   joins=>[],joins=>[],constraints=>[]);
Class::AutoClass::declare(__PACKAGE__);

sub connectdots {$_[0]->connectortable->connectdots;}
sub name {$_[0]->connectortable->name;}
sub columns {$_[0]->connectortable->columns;}
sub column2cs {$_[0]->connectortable->column2cs;}
sub db {$_[0]->connectortable->db;}

sub ct_aliases {
  my $self=shift @_;
  my $name2ct_alias=$self->name2ct_alias;
  if (@_) {
    $self->throw("Cannot set ct_aliases: name2ct_alias is already set and it takes precedence")
      if $name2ct_alias;
    return $self->_ct_aliases(@_);
  }
  $name2ct_alias? [values %$name2ct_alias]: $self->_ct_aliases;
}
sub cs_aliases {
  my $self=shift @_;
  my $name2cs_alias=$self->name2cs_alias;
  if (@_) {
    $self->throw("Cannot set cs_aliases: name2cs_alias is already set and it takes precedence")
      if $name2cs_alias;
    return $self->_cs_aliases(@_);
  }
  $name2cs_alias? [values %$name2cs_alias]: $self->_cs_aliases;
}
sub aliases {
  my @aliases=(@{$_[0]->ct_aliases},@{$_[0]->cs_aliases});
  wantarray? @aliases: \@aliases;
}

sub execute {
  my($self)=@_;
  $self->parse;			# parse syntax
  $self->normalize;		# normalize syntax
  $self->validate;		# do semantic checks
  $self->db_execute;	# really execute -- implemented in subclasses
}

sub parse {
  my($self)=@_;
  $self->parse_aliases;
  $self->parse_constraints;
  $self->parse_joins;
}
sub normalize {
  my($self)=@_;
  $self->normalize_aliases;
  $self->normalize_constraints;
  $self->normalize_joins;
  $self->fill_aliases;		# fill in additional aliases from Constraints and Join
}
sub validate {
  my($self)=@_;
  $self->validate_aliases;
  $self->validate_constraints;
  $self->validate_joins;
  $self->prune_aliases;		# remove any aliases not mentioned in constraints or joins
  $self->set_columns;		# set output columns & check for uniqueness
}
sub fill_aliases {
  my($self)=@_;
  for my $constraint (@{$self->constraints}) {
    my $term=$constraint->term;
    $self->fill_aliases_term($term);
  }
  for my $join (@{$self->joins}) {
    my $term=$join->term0;
    $self->fill_aliases_term($term);
    my $term=$join->term1;
    $self->fill_aliases_term($term);
  }
}
sub fill_aliases_term {
  my($self,$term)=@_;
  my $alias=$term->ct_alias;
  my $old_alias=$self->name2ct_alias->{$alias};
  $self->name2ct_alias->{$alias}=
    new Bio::ConnectDots::ConnectorQuery::Alias(-target_name=>$alias,-alias_name=>$alias)
      if $alias && !$old_alias;
  my $alias=$term->cs_alias;
  my $old_alias=$self->name2cs_alias->{$alias};
  $self->name2cs_alias->{$alias}=
    new Bio::ConnectDots::ConnectorQuery::Alias(-target_name=>$alias,-alias_name=>$alias)
      if $alias && !$old_alias;
}
sub prune_aliases {
  my($self)=@_;
  my @aliases=(map({$_->alias} @{$self->constraints}),map({$_->aliases} @{$self->joins}));
  my %aliases;
  @aliases{@aliases}=@aliases;
  my $pruned=[];
  my($name2ct_alias,$name2cs_alias)=($self->name2ct_alias,$self->name2cs_alias);
  while(my($alias_name,$alias)=each %$name2ct_alias) {
    delete $name2ct_alias->{$alias_name} unless $aliases{$alias};
  }
  while(my($alias_name,$alias)=each %$name2cs_alias) {
    delete $name2cs_alias->{$alias_name} unless $aliases{$alias};
  }
}
sub set_columns {
  my($self)=@_;
  my $column2cs=$self->column2cs;
  for my $ct_alias (@{$self->ct_aliases}) {
    my $ct=$ct_alias->target_object;
    while(my($column,$cs)=each %{$ct->column2cs}) {
      my $out_column=$self->out_column($ct_alias,$column);
      $self->throw("Duplicate output column $out_column from ConnectorTable ".$ct->name)
	if defined $column2cs->{$out_column};
      $column2cs->{$out_column}=$cs;
    }
  }
  for my $cs_alias (@{$self->cs_aliases}) {
    my $cs=$cs_alias->target_object;
    my $out_column=$self->out_column($cs_alias);
    $self->throw("Duplicate output column $out_column for ConnectorSet ".$cs->name)
      if defined $column2cs->{$out_column};
    $column2cs->{$out_column}=$cs;
  }
}
sub out_column {
  my $self=shift @_;
  my $out_column;
  my($ct_alias,$ct_column,$cs_aliase);
  if (@_==1) {
    my($cs_alias)=@_;
    $out_column=$cs_alias->alias_name;
  } elsif (@_==2) {
    my($ct_alias,$column)=@_;
    $out_column=$ct_alias->alias_name.'_'.$column;
  } else {
    $self->throw("Wrong number parameters to out_column: should be 1 or 2, not".(@_+0));
  }
  $out_column;
}

sub parse_aliases {
  my($self)=@_;
  my $ct_aliases=parse Bio::ConnectDots::ConnectorQuery::Alias($self->ct_aliases);
  $self->ct_aliases($ct_aliases);
  my $cs_aliases=parse Bio::ConnectDots::ConnectorQuery::Alias($self->cs_aliases);
  $self->cs_aliases($cs_aliases);
}
# convert alias ARRAY to HASH -- check for inconsistent duplicate entries
sub normalize_aliases {
  my($self)=@_;
  my $name2ct_alias=$self->_normalize_aliases($self->ct_aliases);
  $self->name2ct_alias($name2ct_alias);
  my $name2cs_alias=$self->_normalize_aliases($self->cs_aliases);
  $self->name2cs_alias($name2cs_alias);
}
sub _normalize_aliases {
  my($self,$aliases)=@_;
  my $normalized={};
  for my $alias (@$aliases) {
    my $alias_name=$alias->alias_name;
    my $target_name=$alias->target_name;
    my $old_alias=$normalized->{$alias_name};
    my $old_target=$old_alias && $old_alias->target_name;
    $self->throw("Duplicate alias $alias_name refers to different targets: $old_target vs. $target_name") if $old_target && $old_target ne $target_name;
    $normalized->{$alias_name}=new Bio::ConnectDots::ConnectorQuery::Alias(-target_name=>$target_name,-alias_name=>$alias_name);
  }
  wantarray? %$normalized: $normalized;
}

sub validate_aliases {
  my($self)=@_;
  $self->_validate_aliases($self->name2ct_alias,$self->connectdots->name2ct,0);
  $self->_validate_aliases($self->name2cs_alias,$self->connectdots->name2cs,1);
}
sub _validate_aliases {
  my($self,$name2alias,$name2object,$cs)=@_;
  my $cs2version = $self->connectortable->cs2version;
  while(my($alias_name,$alias_obj)=each %$name2alias) {
		if ($cs) {
	  	my $csname=$alias_obj->target_name;
	    my $version=$cs2version->{$csname};
			# make sure object exists  	
	  	$self->throw("Unknown ConnectorSet: $csname") unless $name2object->{$csname};
	  	$self->throw("Unknown version: $version for connectorset $csname") unless $version;
	    $alias_obj->validate($name2object,$version);
		} else {
			# make sure object exists  	
	  	my $ctname=$alias_obj->target_name;
	  	$self->throw("Unknown ConnectorTable: $ctname") unless $name2object->{$ctname};
	    $alias_obj->validate($name2object);
		}
  }
}

sub parse_constraints {
  my($self)=@_;
  my $constraints=parse Bio::ConnectDots::ConnectorQuery::Constraint($self->constraints);
  $self->constraints($constraints);
}
sub normalize_constraints {
  my($self)=@_;
  my $constraints=$self->constraints;
  my $normalized=[];
  @$normalized=map {$_->normalize} @$constraints;
  $self->constraints($normalized);
}
sub validate_constraints {
  my($self)=@_;
  my $constraints=$self->constraints;
  my($name2ct_alias,$name2cs_alias)=($self->name2ct_alias,$self->name2cs_alias);
  map {$_->validate($name2ct_alias,$name2cs_alias)} @$constraints;
}

sub parse_joins {
  my($self)=@_;
  my $joins=parse Bio::ConnectDots::ConnectorQuery::Join($self->joins);
  $self->joins($joins);
}
sub normalize_joins {
  my($self)=@_;
  my $joins=$self->joins;
  my $normalized=[];
  @$normalized=map {$_->normalize} @$joins;
  $self->joins($normalized);
}
sub validate_joins {
  my($self,$ct_alias,$cs_alias)=@_;
  my $joins=$self->joins;
  my($name2ct_alias,$name2cs_alias)=($self->name2ct_alias,$self->name2cs_alias);
  map {$_->validate($name2ct_alias,$name2cs_alias)} @$joins;
}

1;
__END__
=head1 NAME

Bio::ConnectDots::ConnectorQuery

=head1 DESCRIPTION

Base class for the query subclasses relating to ConnectorTables

Allowable input formats for constraints are

  'data op constant AND ...' (note: op is optional)

  or ARRAY of the following

  'data op constant AND ...'
  [<data> <constant>]
  [<data> op <constant>]
  {alias=>'data op constant'
   {
    alias=>[<data> <constant>]}
   {
     alias=>[<data> op <constant>]}
   {
     alias=>{columm=>'data op constant'}, ...}
   {
     alias=>{columm=>[<data> <constant>]}, ...}
   {
     alias=>{columm=>[<data> op <constant>]}, ...}

or HASH containing any hash form where data is 
  
  alias or alias.label or alias.column.label

label is 

  label_name or [label_name ...] or '*'
   
constant is 

  string or [string...]

=head1 AUTHOR - David Burdick, Nat Goodman

Email dburdick@systemsbiology.org, natg@shore.net

=head1 COPYRIGHT

Copyright (c) 2005 Institute for Systems Biology (ISB). All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=cut