package Bio::ConnectDots::ConnectorQuery::Operator::CsCsJoin;
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

# What we used to call a 'rod join'

sub generate {
  my($self)=@_;
  my $join=$self->join;
  my @inputs=@{$self->inputs};

  my @input_names=map {$_->sql_name} @inputs;
  my @sql_aliases=map {$_->sql_alias} @inputs;
  my @cs_sql_aliases=@sql_aliases;              # input cs-like objects
  my @cs_ids=$join->cs_ids;
  my @label_ids=$join->label_ids;               # pair of ARRAYs

  my @cs_wheres=map {qq($cs_sql_aliases[$_].connectorset_id=$cs_ids[$_])} (0..1);
  my @cs_label_wheres=map{$self->label_where($cs_sql_aliases[$_],$label_ids[$_])} (0..1);
  my $dot_where=qq($cs_sql_aliases[0].dot_id=$cs_sql_aliases[1].dot_id);

  my @cs_froms=map {qq($input_names[$_] AS $cs_sql_aliases[$_])} (0..1);

  my @targets=map {$self->targets($cs_sql_aliases[$_],$inputs[$_])} (0..1);
  my $targets=join(', ',@targets);
  my $on=joindef(' AND ',@cs_wheres,@cs_label_wheres,$dot_where);

  my $left_join=
    join(' ',
	 qq(SELECT $targets FROM $cs_froms[0] LEFT JOIN $cs_froms[1] ON $on),
	 qq(WHERE),joindef(' AND ',$cs_wheres[0],$cs_label_wheres[0]));
  my $right_join=
    join(' ',
	 qq(SELECT $targets FROM $cs_froms[1] LEFT JOIN $cs_froms[0] ON $on),
	 qq(WHERE),joindef(' AND ',$cs_wheres[1],$cs_label_wheres[1]));
  my $sql="($left_join) UNION ($right_join)";
  $self->sql($sql);

  # sql_columns needed to workaround bug in MySQL 4.0.14 that causes
  #   very poor performance when joining large numbers of NULLs
  map {s/^.* AS //i} @targets;	# updates @targets in place
  $self->sql_columns(\@targets);
}
1;
