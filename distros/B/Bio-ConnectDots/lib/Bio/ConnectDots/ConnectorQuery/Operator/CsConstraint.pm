package Bio::ConnectDots::ConnectorQuery::Operator::CsConstraint;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Class::AutoClass;
use Bio::ConnectDots::Util;
use Bio::ConnectDots::ConnectorQuery::Operator::Constraint;
@ISA = qw(Bio::ConnectDots::ConnectorQuery::Operator::Constraint);

@AUTO_ATTRIBUTES=qw();
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);

sub generate {
  my($self,$distinct,$targets)=@_;	# CsRootConstraint calls us with $distinct,$targets set
  my $constraints=$self->constraints;
  my $input=$self->input;
  my $input_name=$input->sql_name;
  my $cs_sql_alias_base=$input->sql_alias;    # use canonical sql alias as base
  my $cs_sql_aliases=$self->cs_sql_aliases;
  my @where;

  # this loop generates where terms for each individual constraint 
  for (my $i=0; $i<@$constraints; $i++) {
    my $constraint=$constraints->[$i];
    my $term=$constraint->term;
    my $cs_sql_alias=$cs_sql_alias_base."_$i";
    push(@$cs_sql_aliases,$cs_sql_alias);
    push(@where,
	 $self->cs_term_where($term,$cs_sql_alias),
	 $self->constraint_where($constraint,$cs_sql_alias));
  }
  # need one more connectdot alias to handle existential quanitifier, ie,
  # so we get all connectdot rows for connectors that pass the constraint
  # (don't put this in 'from', since it will be named in STRAIGHT JOIN clause)
  my $cs_id=$constraints->[0]->cs_id;
  push(@where,"cd.connectorset_id=$cs_id");
  # connect each cs_sql_alias to this one
  for my $cs_sql_alias (@$cs_sql_aliases) {
    push(@where,"cd.connector_id=$cs_sql_alias.connector_id");
  }
  $targets or $targets="cd.connector_id, cd.connectorset_id, cd.label_id, cd.dot_id";
  my @from=$self->cs_from;
  my $straight_join="STRAIGHT_JOIN connectdot cd USE INDEX (connectorset_id)";
  my $from=join(', ',@from);
  my $where=joindef(' AND ',@where);
  my $sql="SELECT $distinct $targets FROM $from $straight_join WHERE $where";
  $self->sql($sql);
  $self->indexed_columns([qw(connector_id dot_id)]);
}
# Override default
sub targets {$_[0]->input->targets($_[1]);}

1;
