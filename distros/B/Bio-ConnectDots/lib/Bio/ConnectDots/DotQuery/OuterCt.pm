package Bio::ConnectDots::DotQuery::OuterCt;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use DBI;
use Class::AutoClass;
use Bio::ConnectDots::Util;
use Bio::ConnectDots::DotQuery;
use Bio::ConnectDots::DotQuery::CtMixin;
@ISA = qw(Bio::ConnectDots::DotQuery Bio::ConnectDots::DotQuery::CtMixin);

@AUTO_ATTRIBUTES=qw();
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  $self->{centric} = $args->centric;
  $self->{remove_subsets} = $args->remove_subsets;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  $self->execute if $args->execute;
}

sub db_execute {
  my($self)=@_;
  my $db=$self->db;
  $self->throw("Cannot run query: database is not connected") unless $db->is_connected;
  $self->throw("Cannot run query: database does not exist") unless $db->exists;
  my $name=$self->name;
  my $preview = $self->dottable->preview;
	my $plimit = $self->dottable->preview_limit;

  my %cds; # hash on {cs_id}{label_id} -> cd#
  my(@targets,@columns,@left_joins,@where);
  # we're doing a star join. use left join to combine 'points'
  my $i=0;
  my %out_cols;
  for my $output (@{$self->outputs}) {
    my($output_name,$column,$cs_id,$label_id)=$output->get(qw(output_name column cs_id label_id));
		$out_cols{$column} = 1;
    my $cd="cd$i";
    push(@targets,"$cd.id AS $output_name");
    push(@columns,$output_name);
    my $on= "ON ct.$column=$cd.connector_id";
		my $subselect = "(SELECT * FROM connectdot WHERE connectorset_id=$cs_id AND label_id=$label_id";
		$subselect .= " LIMIT $plimit" if $preview;
		$subselect .= ") AS $cd $on";		
    push(@left_joins,$subselect);
    $cds{$cs_id}{$label_id} = $cd;
    $i++;
  }

  my @tables=("(SELECT ". join(',', keys %out_cols) ." FROM ". $self->input .") AS ct");
    
  for my $constraint (@{$self->constraints}) {
    my($column,$cs_id)=($constraint->column,$constraint->cs_id);
		my $label_id = $constraint->label_ids->[0];
		next unless $cs_id && $label_id && $column;
    my $cd="cd$i";
    my $on= "ON ct.$column=$cd.connector_id";
		my $subselect = "(SELECT * FROM connectdot WHERE connectorset_id=$cs_id AND label_id=$label_id";
		$subselect .= " LIMIT $plimit" if $preview;
		$subselect .= ") AS $cd $on";		
    push(@left_joins,$subselect);
    $cds{$cs_id}{$label_id} = $cd;
    $i++;
	  push(@where,$self->constraint_where($constraint,$cs_id,$cd));
  }

  my $targets=join(', ',@targets);
  my $tables=join(', ',@tables);
  my $left_joins=join(' LEFT JOIN ',@left_joins);
  my $where=@where? "WHERE ".join(' AND ',@where): undef;
  my $sql="SELECT DISTINCT $targets FROM $tables LEFT JOIN $left_joins $where";
  $db->create_table_sql($name,$sql,\@columns);
  
  # make it centric 
  $db->do_sql("DELETE FROM $name WHERE $self->{centric} IS NULL") if $self->{centric};
  
  # remove subsets
  my @col_names;
  grep push(@col_names,/.*AS (.+)/), @targets; # get col names from targets AS clause
  $self->remove_subsets($db->{dbh}, $name,$self->{remove_subsets}, \@col_names) if $self->{remove_subsets};
 }
 

1;
