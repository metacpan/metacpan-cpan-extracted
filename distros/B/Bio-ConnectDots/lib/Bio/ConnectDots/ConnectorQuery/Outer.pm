package Bio::ConnectDots::ConnectorQuery::Outer;
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
use Bio::ConnectDots::SimpleGraph;
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
  my %edge2on;	# translates the edge bewteen two nodes (concatenated as the key) to the ON clause that links them
  my %node2subselect;	# translates the cs_alias to it's corresponding subselect
	my %constr_check; # {connectorset id}->{label id}
  my $i=0;
  my $SimpleGraph = new Bio::ConnectDots::SimpleGraph();	# graph scaffold for join tree building
  my(@targets,@from,@where);

  # initialize cs alias to sql_aliases to empty ARRAYs for each alias
  for my $cs_alias (@{$self->cs_aliases}) {
    $cs_alias2sql_aliases->{$cs_alias}=[];
  }

  # generate constraint where clauses
  for my $constraint (@{$self->constraints}) {
  	my $cs_id = $constraint->{_term}->{target_object}->{db_id};
  	my $label_ids = $constraint->{_term}->{label_ids};
		foreach my $lid (@$label_ids) {
	  	if($constr_check{$cs_id}->{$lid}) {
	  		my $csname = $constraint->{_term}->{cs_alias}->{alias_name};
	  		$self->throw ("Error in Query Syntax: Use IN operator for multiple values from the same ConnectorSet ($csname)");
	  	} 
		}
		foreach my $lid (@$label_ids) { $constr_check{$cs_id}->{$lid}=1 };
		my $result=$self->constraint_where($constraint,\$i);
		push(@where,@{$result->{where}}) if $result->{where};
		my $cd = $result->{cd};
		my $constrHash = $result->{term_where};
		$node2subselect{$cd} = "(SELECT * FROM connectdot WHERE ". join(' AND ', @{ $constrHash->{constraints} });
		$node2subselect{$cd} .= " LIMIT $plimit" if $preview;
		$node2subselect{$cd} .= ") AS $cd";	
		
  }
  # generate dot where clauses (cs-label-dot-label-cs)
  for my $join (@{$self->joins}) {
		my $constrHash = $self->dot_where($join,\$i);
		
		# Add ct-cs inner join if there
		push(@where, @{$constrHash->{term0}->{inner_join}}) if $constrHash->{term0}->{inner_join};			 
		push(@where, @{$constrHash->{term1}->{inner_join}}) if $constrHash->{term1}->{inner_join};			 
		
		my $cd0 = $constrHash->{term0}->{cd};
		my $cd1 = $constrHash->{term1}->{cd};
		
		$node2subselect{$cd0} = "(SELECT * FROM connectdot WHERE ". join(' AND ', @{ $constrHash->{term0}->{constraints} });
		$node2subselect{$cd0} .= " LIMIT $plimit" if $preview;
		$node2subselect{$cd0} .= ") AS $cd0";	
		$node2subselect{$cd1} = "(SELECT * FROM connectdot WHERE ". join(' AND ', @{ $constrHash->{term1}->{constraints} });
		$node2subselect{$cd1} .= " LIMIT $plimit" if $preview;
		$node2subselect{$cd1} .= ") AS $cd1";	
		my $key = ($cd0 lt $cd1)? $cd0.$cd1 : $cd1.$cd0;	# put lexically least cs first
		$edge2on{$key} = "ON $constrHash->{outer_join_on}";
		$SimpleGraph->add_edge($cd0, $cd1);
	  }
	  
	
	  # generate ON clauses to connect sql_aliases for same cs_alias
	  # ex: LocusLink_cs_0.connector_id=LocusLink_cs_4.connector_id
	  for my $sql_aliases (values %$cs_alias2sql_aliases) {
		next unless @$sql_aliases >= 2; # no joins necessary unless 2 or more tables
		for(my $i=0;$i<@$sql_aliases-1;$i++) {
		  my $cd0=$sql_aliases->[$i];
		  my $cd1=$sql_aliases->[$i+1];
		  my $key = ($cd0 lt $cd1)? $cd0.$cd1 : $cd1.$cd0;	# put lexically least cs first
		  $edge2on{$key} = "ON $cd0.connector_id=$cd1.connector_id";
		  $SimpleGraph->add_edge($cd0, $cd1);
		}
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
		$fromsql = "(SELECT * FROM $ct_name LIMIT $plimit) AS $sql_alias" if $preview;
    push(@from,$fromsql);
  }

  # create full outer joins from DFS of join graph
  throw("Joins must form a connected graph! Check that all joins connect to each other") unless $SimpleGraph->is_connected;
  my @edges = $SimpleGraph->edges();
  my $fojs; # full outer joins
  my $n=0;
  my $iterator = $SimpleGraph->edge_traversal($edges[0],'depth first'); 
  # interate through edges, removing nodes from the options as we go
  while($iterator->has_next) {
  	my $edge = $iterator->get_next;
	if ($edge) {
	  if ($n == 0) {
	  	$fojs .= " ". $node2subselect{$edge->[0]} ." FULL OUTER JOIN ". $node2subselect{$edge->[1]};
	  	$fojs .=  " ". $edge2on{$edge->[0] . $edge->[1]};
	  	$node2subselect{$edge->[0]} = undef;
	  	$node2subselect{$edge->[1]} = undef;
	  	$n++;	
	  }
	  else {
		# choose node that has not been added yet
		my $cs_to_add = $node2subselect{$edge->[0]}? $edge->[0] : $edge->[1];
	  	$fojs .= " FULL OUTER JOIN ". $node2subselect{$cs_to_add};
	  	$fojs .=  " ". $edge2on{$edge->[0] . $edge->[1]};	
	  	$node2subselect{$cs_to_add} = undef; # delete it
	  	$n++;
	  }
	}
  }
  push(@from, $fojs);

  my $targets=join(', ',@targets);
  my $from=join(', ',@from);
  my $where=joindef(' AND ',@where);
  my $sql="SELECT DISTINCT $targets FROM $from";
  $sql .= " WHERE $where" if $where;
  my @indexes=@{$self->columns};
  $db->create_table_sql($name,$sql,\@indexes);
}

sub dot_where {
  my($self,$join,$i_ref)=@_;
  my %results;
  my $term_rslt0 = $self->term_where($join->term0,$i_ref);
  my $cd0 = $term_rslt0->{cd};
  $results{term0} = $term_rslt0;
  my $term_rslt1 = $self->term_where($join->term1,$i_ref);
  my $cd1 = $term_rslt1->{cd};
  $results{term1} = $term_rslt1;
  foreach my $term (keys %results) {
	my $cd = $results{$term}->{cd};
  	foreach my $constraint (@{ $results{$term}->{constraints} }) {
  		$constraint =~ s/^$cd\.//;
  	}	
  }
  $results{outer_join_on} = "$cd0.dot_id=$cd1.dot_id";
  return \%results;  
}

sub constraint_where {
  my($self,$constraint,$i_ref)=@_;
	my %results;
  my $db=$self->db;
  my @where;
  my ($hash, $cd) = $self->term_where($constraint->term,$i_ref);
  my $where = $hash->{constraints}; 
  push(@where,@$where);
  my($op,$constants)=($constraint->op,$constraint->constants);
  my @constants=map {$db->quote_dot($_)} @$constants;
  if ($op=~/IN/) {		# IN or NOT IN
    push(@where,"$cd.id $op (".join(',',@constants).")");
  } elsif ($op ne 'EXISTS') {	# EXISTS has no constants -- needs no SQL condition
				# should only be 1 constant by now -- see Constraint::normalize
    push(@where,"$cd.id $op ".$db->quote($constants->[0]));
  }
  $results{where} = \@where;
  $results{cd} = $cd;
  $results{term_where} = $hash;
 	foreach my $constraint (@{ $results{term_where}->{constraints} }) {
 		$constraint =~ s/^$cd\.//;
 	}	
  
  return \%results;
}
sub term_where {
  my($self,$term,$i_ref)=@_;
  my %ret;
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
    push(@{$ret{inner_join}},"$ct_sql_alias.$column=$cs_sql_alias.connector_id"); # inner join 
  }
  push(@{$ret{constraints}},"$cs_sql_alias.connectorset_id=$cs_id");
  # if $label_ids is empty, the label was '*' -- matches all ids
  my $label_ids=$term->label_ids;
  if (@$label_ids==1) {
    push(@{$ret{constraints}},"$cs_sql_alias.label_id=".$label_ids->[0]);
  } elsif (@$label_ids>1) {
    push(@{$ret{constraints}},"$cs_sql_alias.label_id IN (".join(',',@$label_ids).")");
  }
  $ret{cd} = $cs_sql_alias;
  wantarray? (\%ret, $cs_sql_alias): \%ret;
}

sub connector_where {
}
1;
