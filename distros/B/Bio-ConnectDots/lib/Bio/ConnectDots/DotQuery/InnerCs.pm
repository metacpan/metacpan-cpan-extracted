package Bio::ConnectDots::DotQuery::InnerCs;
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

  my(@targets,@columns,@tables,@where);
  my $i=0;
  my $cd0;
  for my $output (@{$self->outputs}) {
    my($output_name,$label_id)=($output->output_name,$output->label_id);
    my $cd1="cd$i";
    push(@targets,"$cd1.id AS $output_name");
    push(@columns,$output_name);
		if($preview) {
			push(@tables,"(SELECT * FROM connectdot WHERE connectorset_id=$cs_id AND label_id=$label_id LIMIT $plimit) AS cd$i");
		} else {
	    push(@tables,"connectdot AS cd$i");
		}
    push(@where,"$cd0.connector_id=$cd1.connector_id") unless $i==0;
    push(@where,("$cd1.connectorset_id=$cs_id",
								 "$cd1.label_id=$label_id"));
    $i++;
    $cd0=$cd1;
  }
  for my $constraint (@{$self->constraints}) {
    my $cd1="cd$i";
    push(@tables,"connectdot AS $cd1"); # from
    push(@where,"$cd0.connector_id=$cd1.connector_id") unless $i==0; # join
    push(@where,$self->constraint_where($constraint,$cs_id,$cd1));
    $i++;
    $cd0=$cd1;
  }
  my $targets=join(', ',@targets);
  my $from=join(', ',@tables);
  my $where=join(' AND ',@where);
  my $sql="SELECT DISTINCT $targets FROM $from WHERE $where";
  $db->create_table_sql($name,$sql,\@columns)
}


1;
