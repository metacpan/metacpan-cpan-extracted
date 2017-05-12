package Bio::ConnectDots::ConnectorQuery::Operator::CtConstraint;
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
  my($self)=@_;
  my $constraints=$self->constraints;
  my $input=$self->input;
  my $input_name=$input->sql_name;
  my $ct_sql_alias=$input->sql_alias;
  my $cs_sql_aliases=$self->cs_sql_aliases;
  my @where;

  # this loop generates where terms for each individual constraint 
  for (my $i=0; $i<@$constraints; $i++) {
    my $constraint=$constraints->[$i];
    my $term=$constraint->term;
    my $cs_sql_alias=$term->cs_name."_$i";
    push(@$cs_sql_aliases,$cs_sql_alias);
    push(@where,
	 $self->ct_term_where($term,$input,$ct_sql_alias,$cs_sql_alias),
	 $self->constraint_where($constraint,$cs_sql_alias));
  }
  # collect targets (columns that are output)
  my @targets=$self->targets($ct_sql_alias,$input);
  my @from=($input_name." AS $ct_sql_alias",$self->cs_from);
  
  # assemble the sql
  my $targets=join(', ',@targets);
  my $from=join(', ',@from);
  my $where=joindef(' AND ',@where);
  my $sql="SELECT $targets FROM $from WHERE $where";
  $self->sql($sql);
}


1;
