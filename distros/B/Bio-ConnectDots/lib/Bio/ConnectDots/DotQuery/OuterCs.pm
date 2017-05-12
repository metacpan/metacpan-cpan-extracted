package Bio::ConnectDots::DotQuery::OuterCs;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use DBI;
use Class::AutoClass;
use Bio::ConnectDots::Util;
use Bio::ConnectDots::DotQuery;
use Bio::ConnectDots::DotQuery::CsMixin;
@ISA = qw(Bio::ConnectDots::DotQuery Bio::ConnectDots::DotQuery::CsMixin);

@AUTO_ATTRIBUTES=qw();
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=();
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
  my $cs_id=$self->cs_id;
  my $preview = $self->dottable->preview;
	my $plimit = $self->dottable->preview_limit;

  my(@targets,@columns,@fo_joins);
  my @where;
  my %cslabel2cd;
  my $i=0;
  # use full outer join for star join
  my $firstcd = "cd";
  my $subselect = "(SELECT * FROM connectdot WHERE connectorset_id=$cs_id";
  $subselect .= " LIMIT $plimit" if $preview;
  $subselect .= ") AS $firstcd";
  push(@fo_joins,$subselect); # center of star
  for my $output (@{$self->outputs}) {
    my($output_name,$label_id)=($output->output_name,$output->label_id);
    my $cd="cd$i";
    push(@targets,"$cd.id AS $output_name");
    push(@columns,$output_name);
    my $on= "ON $firstcd.connector_id=$cd.connector_id";
	  my $subselect = "(SELECT * FROM connectdot WHERE connectorset_id=$cs_id AND label_id=$label_id";
	  $subselect .= " LIMIT $plimit" if $preview;
	  $subselect .= ") AS $cd $on";
    push(@fo_joins,$subselect);
    $cslabel2cd{$cs_id}->{$label_id} = $cd;
    $i++;
  }

  # add constraints
  for my $constraint (@{$self->constraints}) {
	foreach my $label_id (@{ $constraint->label_ids }) {
	  my $this_cd = $cslabel2cd{$cs_id}->{$label_id};
	  push(@where,$self->constraint_where($constraint,$cs_id,$this_cd));
	}
  }


  my $targets=join(', ',@targets);
  my $fo_joins=join(' FULL OUTER JOIN ',@fo_joins);
  my $where=join(' AND ',@where);
  my $sql="SELECT DISTINCT $targets FROM $fo_joins";
  $sql .=" WHERE $where" if $where;
  $db->create_table_sql($name,$sql,\@columns);
  
  # make it centric 
  $db->do_sql("DELETE FROM $name WHERE $self->{centric} IS NULL") if $self->{centric};
  
  # remove subsets
  my @col_names;
  grep push(@col_names,/.*AS (.+)/), @targets; # get col names from targets AS clause
  $self->remove_subsets($db->{dbh}, $name,$self->{remove_subsets}, \@col_names) if $self->{remove_subsets};
}


1;
