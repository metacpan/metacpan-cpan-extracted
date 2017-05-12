package Bio::ConnectDots::ConnectorQuery::Inner;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use DBI;
use Class::AutoClass;
use Bio::ConnectDots::Util;
use Bio::ConnectDots::ConnectorTable;
use Bio::ConnectDots::ConnectorQuery;
use Bio::ConnectDots::ConnectorQuery::Alias;
use Bio::ConnectDots::ConnectorQuery::Term;
use Bio::ConnectDots::ConnectorQuery::Constraint;
use Bio::ConnectDots::ConnectorQuery::Join;
@ISA = qw(Bio::ConnectDots::ConnectorQuery);

@AUTO_ATTRIBUTES=qw(cs_sql_aliases ct_alias2sql_alias cs_alias2sql_aliases);
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=(cs_sql_aliases=>[],ct_alias2sql_alias=>{},cs_alias2sql_aliases=>{});
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  $self->execute if $args->execute;
}

sub db_execute {
  my($self)=@_;
  my $db=$self->db;
  $self->throw("Cannot run query: database is not connected") unless $db->is_connected;
  $self->throw("Cannot run query: database does not exist") unless $db->exists;
  my $name=$self->name;
	my $preview = $self->connectortable->preview;
	my $plimit = $self->connectortable->preview_limit;
  my $ct_alias2sql_alias=$self->ct_alias2sql_alias;
  my $cs_alias2sql_aliases=$self->cs_alias2sql_aliases;
  # initialize cs alias to sql_aliases to empty ARRAYs for each alias
  for my $cs_alias (@{$self->cs_aliases}) {
    $cs_alias2sql_aliases->{$cs_alias}=[];
  }
  my(@targets,@from,@where,@where_cw);
  # generate dot where clauses (cs-label-dot-label-cs)
  my $i=0;
  for my $join (@{$self->joins}) {
    push(@where,$self->dot_where($join,\$i));
  }
  
  # generate constraint where clauses
  for my $constraint (@{$self->constraints}) {
    push(@where,$self->constraint_where($constraint,\$i));
  }
  # generate clauses to connect sql_aliases for same cs_alias
  for my $sql_aliases (values %$cs_alias2sql_aliases) {
    push(@where_cw,$self->connector_where($sql_aliases));
  }
  # collect targets (columns that are output)
  # for ct_aliases, need all columns -- col name prefixed with ct_alias
  for my $ct_alias (@{$self->ct_aliases}) {
    my $ct=$ct_alias->target_object;
    my $ct_alias_name=$ct_alias->alias_name;
    my $sql_alias=$ct_alias2sql_alias->{$ct_alias};
    for my $column (@{$ct->columns}) {
      my $column_name=$ct_alias_name.'_'.$column;
      push(@targets,"$sql_alias.$column AS $column_name");
    }
  }
  # for cs_aliases, need connector_id from one sql_alias -- col name = cs_alias
  for my $cs_alias (@{$self->cs_aliases}) {
    my $cs_alias_name=$cs_alias->alias_name;
    my $sql_aliases=$cs_alias2sql_aliases->{$cs_alias};
    push(@targets,$sql_aliases->[0].".connector_id AS ".$cs_alias_name);
  }
  # assemble 'from' list
  # each ct_alias refers to its own ConnectorTable
  for my $ct_alias (@{$self->ct_aliases}) {
    my $ct=$ct_alias->target_object;
    my $ct_name=$ct->name;
    my $sql_alias=$ct_alias2sql_alias->{$ct_alias};
		my $fromsql = "$ct_name AS $sql_alias";
		if ($preview) { #add where clauses for this alias to subselect
			my @subwhere;
			foreach my $constr (@where) {
				if($constr =~ /label_id/ || $constr =~ /connectorset_id/) {
					my ($constraint) = $constr =~ /$sql_alias\.(.+)/;
					push @subwhere, $constraint if $constraint;
				}
			}
			my $subwhere = join(' AND ',@subwhere);
			$fromsql = "(select * from $ct_name WHERE $subwhere LIMIT $plimit) AS $sql_alias" if $preview;			
		}
    push(@from,$fromsql);
  }
  # all cs_aliases refer to connectdot
  for my $sql_alias (uniq($self->cs_sql_aliases)) {
		my $fromsql = "connectdot AS $sql_alias";
		if ($preview) { #add where clauses for this alias to subselect
			my @subwhere;
			foreach my $constr (@where) {
				if($constr =~ /label_id/ || $constr =~ /connectorset_id/) {
					my ($constraint) = $constr =~ /$sql_alias\.(.+)/;
					push @subwhere, $constraint if $constraint;
				}
			}
			my $subwhere = join(' AND ',@subwhere);
			$fromsql = "(select * from connectdot WHERE $subwhere LIMIT $plimit) AS $sql_alias" if $preview;			
		}
    push(@from,$fromsql);
  }

  my $targets=join(', ',@targets);
  my $from=join(', ',@from);
  my $where=joindef(' AND ',(@where,@where_cw));
  my $sql="SELECT DISTINCT $targets FROM $from WHERE $where";
  my @indexes=@{$self->columns};
  $db->create_table_sql($name,$sql,\@indexes);
}

sub dot_where {
  my($self,$join,$i_ref)=@_;
  my @where;
  my($where0,$cd0)=
    $self->term_where($join->term0,$i_ref);
  my($where1,$cd1)=
    $self->term_where($join->term1,$i_ref);
  push(@where,@$where0,@$where1);
  push(@where,"$cd0.dot_id=$cd1.dot_id");
  wantarray? @where: \@where; 
}
sub constraint_where {
  my($self,$constraint,$i_ref)=@_;
  my $db=$self->db;
  my @where;
  my($where,$cd)=
    $self->term_where($constraint->term,$i_ref);
  push(@where,@$where);
  my($op,$constants)=($constraint->op,$constraint->constants);
  my @constants=map {$db->quote_dot($_)} @$constants;
  if ($op=~/IN/) {		# IN or NOT IN
    push(@where,"$cd.id $op (".join(',',@constants).")");
  } elsif ($op ne 'EXISTS') {	# EXISTS has no constants -- needs no SQL condition
				# should only be 1 constant by now -- see Constraint::normalize
    push(@where,"$cd.id $op ".$db->quote($constants->[0]));
  }
  wantarray? @where: \@where;
}
sub term_where {
  my($self,$term,$i_ref)=@_;
  my $where=[];
  my $ct_alias=$term->ct_alias;
  my $cs_alias=$term->cs_alias;
  my $cs=$term->cs;		# always defined, but can be from column or from alias
  my $cs_id=$cs->db_id;
  my $cs_sql_alias=($cs_alias? $cs_alias->alias_name: $cs->name).'_cs_'.$$i_ref++;
  push(@{$self->cs_alias2sql_aliases->{$cs_alias}},$cs_sql_alias) if $cs_alias;
  push(@{$self->cs_sql_aliases},$cs_sql_alias);
  if ($ct_alias) {
    my $ct=$term->ct;
    my $ct_sql_alias=$self->ct_alias2sql_alias->{$ct_alias} ||
      ($self->ct_alias2sql_alias->{$ct_alias}=$ct_alias->alias_name.'_ct_'.$$i_ref++);
    my $column=$term->column;
    push(@$where,"$ct_sql_alias.$column=$cs_sql_alias.connector_id");
  }
  push(@$where,"$cs_sql_alias.connectorset_id=$cs_id");
  # if $label_ids is empty, the label was '*' -- matches all ids
  my $label_ids=$term->label_ids;
  if (@$label_ids==1) {
    push(@$where,"$cs_sql_alias.label_id=".$label_ids->[0]);
  } elsif (@$label_ids>1) {
    push(@$where,"$cs_sql_alias.label_id IN (".join(',',@$label_ids).")");
  }
  wantarray? ($where,$cs_sql_alias): $where;
}
sub connector_where {
  my($self,$sql_aliases)=@_;
  return unless @$sql_aliases>=2; # no joins necessary unless 2 or more tables
  my @where;
  for(my $i=0;$i<@$sql_aliases-1;$i++) {
    my $cd0=$sql_aliases->[$i];
    my $cd1=$sql_aliases->[$i+1];
    push(@where, "$cd0.connector_id=$cd1.connector_id");
  }
  wantarray? @where: \@where;
}
1;
