package Bio::ConnectDots::QueryGraph;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use Class::AutoClass::Root;
use Class::AutoClass;
use Bio::ConnectDots::SimpleGraph;
@ISA = qw(Bio::ConnectDots::SimpleGraph);

@AUTO_ATTRIBUTES=qw(connectortable edge2rod rod_traversal);
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=(edge2rod=>{});
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  my $connectortable=$self->connectortable;
  my $edge2rod=$self->edge2rod;
  
  $self->add_nodes(keys %{$args->aliases});
  for my $rod (@{$args->rods}) {
    my($alias1,$alias2)=($rod->[0],$rod->[2]); # extract aliases
    $self->add_edge($alias1,$alias2);      # store as edge
    my $edge=$self->edge($alias1,$alias2); # get actual edge from graph
    $edge2rod->{$edge}=$rod;
  }
  my @dup_edges=$self->dup_edges;
  $self->throw("Query has multiple rods between these ConnectorSets or Aliases: ". 
	       join('',map {"@$_".'; '} @dup_edges)) if @dup_edges;
  my @components=$self->components;
  $self->throw("Query is not connected (has ".(@components+0)." components):\n  ".
	       join("\n  ",(map {join(' ',$_->nodes)} @components))) if @components>1;
  $self->throw("Query is circular (contains alternate paths)") unless $self->is_tree;
  my $rod_traversal=$self->edge_traversal(undef,'bfs')->get_all;
  $self->rod_traversal($rod_traversal);

}

1;
