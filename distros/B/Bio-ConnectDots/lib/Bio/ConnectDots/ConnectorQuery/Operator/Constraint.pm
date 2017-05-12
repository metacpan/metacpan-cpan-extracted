package Bio::ConnectDots::ConnectorQuery::Operator::Constraint;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Class::AutoClass;
use Bio::ConnectDots::Util;
use Bio::ConnectDots::ConnectorQuery::Operator;
@ISA = qw(Bio::ConnectDots::ConnectorQuery::Operator);

@AUTO_ATTRIBUTES=qw(constraints cs_sql_aliases);
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=(constraints=>[],cs_sql_aliases=>[]);
Class::AutoClass::declare(__PACKAGE__);

sub ct_term_where {
  my($self,$term,$input,$ct_sql_alias,$cs_sql_alias)=@_;
  my $column_name=$input->term_column($term);
  my @where=($self->cs_term_where($term,$cs_sql_alias),
	     $self->ct_cs_where($term,$input,$ct_sql_alias,$cs_sql_alias));
  wantarray? @where: \@where;
}

sub cs_term_where {
  my($self,$term,$cs_sql_alias)=@_;
  my @where=(qq($cs_sql_alias.connectorset_id=).$term->cs_id,
	     $self->label_where($cs_sql_alias,$term->label_ids));
  wantarray? @where: \@where;
}
sub constraint_where {
  my($self,$constraint,$cs_sql_alias)=@_;
  my $where=[];
  my $db=$self->db;
  my($op,$constants)=($constraint->op,$constraint->constants);
  my @constants=map {$db->quote_dot($_)} @$constants;
  if ($op=~/IN/) {		# IN or NOT IN
    push(@$where,"$cs_sql_alias.id $op (".join(',',@constants).")");
  } elsif ($op ne 'EXISTS') {	# EXISTS has no constants -- needs no SQL condition
				# should only be 1 constant by now -- see Constraint::normalize
    push(@$where,"$cs_sql_alias.id $op ".$db->quote($constants->[0]));
  }
  wantarray? @$where: $where;
}

sub cs_from {
  my($self)=@_;
  my @from=map {"connectdot AS $_"} @{$self->cs_sql_aliases};
  wantarray? @from: \@from;
}

sub source {$_[0]->input->source;}
1;
