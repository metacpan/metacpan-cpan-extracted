package Bio::ConnectDots::ConnectorQuery::Operator::CtCsJoin;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Class::AutoClass;
use Bio::ConnectDots::Util;
use Bio::ConnectDots::ConnectorQuery::Operator::Join;
@ISA = qw(Bio::ConnectDots::ConnectorQuery::Operator::Join);

@AUTO_ATTRIBUTES=qw();
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);

sub generate {
  my($self)=@_;
  my $join=$self->join;
  my @inputs=@{$self->inputs};
  my @input_names=map {$_->sql_name} @inputs;
  my @sql_aliases=map {$_->sql_alias} @inputs;
  my $ct_sql_alias=$sql_aliases[0];             # input ct-like object
  my @cs_sql_aliases=('cd0',$sql_aliases[1]);   # internal cd, input cs-like object
  my @cs_ids=$join->cs_ids;
  my @label_ids=$join->label_ids;               # pair of ARRAYs

  my @cs_wheres=map {qq($cs_sql_aliases[$_].connectorset_id=$cs_ids[$_])} (0..1);
  my @cs_label_wheres=map{$self->label_where($cs_sql_aliases[$_],$label_ids[$_])} (0..1);
  my $ct_cs_where=$self->ct_cs_where($join->term0,$inputs[0],$ct_sql_alias,$cs_sql_aliases[0]);
  my $dot_where=qq($cs_sql_aliases[0].dot_id=$cs_sql_aliases[1].dot_id);
  
  my $ct_from=qq($input_names[0] AS $ct_sql_alias);
  my @cs_froms=(qq(connectdot AS $cs_sql_aliases[0]),
		qq($input_names[1] AS $cs_sql_aliases[1]));

  my @targets=($self->targets($ct_sql_alias,$inputs[0]),
	       $self->targets($cs_sql_aliases[1],$inputs[1]));
  my $targets=join(', ',@targets);

  my $left_join=
    join(' ',
	 qq(SELECT $targets FROM $ct_from LEFT JOIN $cs_froms[0] ON),
	 joindef(' AND ',$cs_wheres[0],$cs_label_wheres[0],$ct_cs_where),
	 qq(LEFT JOIN $cs_froms[1] ON),
	 joindef(' AND ',$cs_wheres[1],$cs_label_wheres[1],$dot_where));
  my $right_join=
    join(' ',
	 qq(SELECT $targets FROM $cs_froms[1] LEFT JOIN $cs_froms[0] ON),
	 joindef(' AND ',$cs_wheres[0],$cs_label_wheres[0],$dot_where),
	 qq(LEFT JOIN $ct_from ON $ct_cs_where),
	 qq(WHERE),joindef(' AND ',$cs_wheres[1],$cs_label_wheres[1]));
  my $sql="($left_join) UNION ($right_join)";
  $self->sql($sql);

  # sql_columns needed to workaround bug in MySQL 4.0.14 that causes
  #   very poor performance when joining large numbers of NULLs
  map {s/^.* AS //i} @targets;	# updates @targets in place
  $self->sql_columns(\@targets);
}

1;
