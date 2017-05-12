package Bio::ConnectDots::DotQuery::InnerCt;
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

  my(@targets,@columns,@where);
	my $subselect = $self->input." AS ct";
	$subselect = "(SELECT * FROM ". $self->input ." LIMIT $plimit) AS ct" if $preview;
  my @tables=($subselect);
  my $i=0;
  for my $output (@{$self->outputs}) {
    my($output_name,$column,$cs_id,$label_id)=$output->get(qw(output_name column cs_id label_id));
    my $cd="cd$i";
    push(@targets,"$cd.id AS $output_name");
    push(@columns,$output_name);
		my $subselect = "connectdot AS cd$i";		
		$subselect = "(SELECT * FROM connectdot WHERE connectorset_id=$cs_id AND label_id=$label_id LIMIT $plimit) AS cd$i" if $preview;
    push(@tables,$subselect);
    push(@where,("ct.$column=$cd.connector_id",
		 "$cd.connectorset_id=$cs_id",
		 "$cd.label_id=$label_id"));
    $i++;
  }
  for my $constraint (@{$self->constraints}) {
    my $cd="cd$i";
    my($column,$cs_id)=($constraint->column,$constraint->cs_id);
    push(@tables,"connectdot AS $cd");
    push(@where,("ct.$column=$cd.connector_id",
		 $self->constraint_where($constraint,$cs_id,$cd)));
    $i++;
  }
  my $targets=join(', ',@targets);
  my $from=join(', ',@tables);
  my $where=join(' AND ',@where);
  my $sql="SELECT DISTINCT $targets FROM $from WHERE $where";
  $db->create_table_sql($name,$sql,\@columns)
}


1;
