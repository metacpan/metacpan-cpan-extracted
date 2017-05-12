# Graph package with non-persistent nodes and edges. this means the entire
# graph is stored and retrieved as a single unit
package Graph;
use strict;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS %AUTODB @EXPORT);
use strict;

@AUTO_ATTRIBUTES=qw(name name2node name2edge);
%DEFAULTS=(nodes=>[],edges=>[],name2node=>{},name2edge=>{});
%AUTODB=(-collection=>'Graph',-keys=>qq(id integer, name string));
Class::AutoClass::declare;

sub nodes {
  my $self=shift;
  my $nodes=@_? $self->{nodes}=$_[0]: $self->{nodes};
  wantarray? @$nodes: $nodes;
}
sub edges {
  my $self=shift;
  my $edges=@_? $self->{edges}=$_[0]: $self->{edges};
  wantarray? @$edges: $edges;
}
sub neighbors {
  my($self,$source)=@_;
  $source->neighbors;
}
sub add_nodes {
  my($self,@names)=@_;
  my $nodes=$self->{nodes};
  my $name2node=$self->name2node;
  for my $name (@names) {
    next if defined $name2node->{$name};
    my $node=new Node(name=>$name);
    push(@$nodes,$node);
    $name2node->{$name}=$node;
  }
}
*add_node=\&add_nodes;

sub add_edges {
  my $self=shift @_;
  my $edges=$self->{edges};
  my $name2edge=$self->name2edge;
  while (@_) {
    my($m,$n);
    if ('ARRAY' eq ref $_[0]) {
      ($m,$n)=@$_[0];
    } else {
      ($m,$n)=(shift,shift);
    }
    last unless defined $m && defined $n;
    $m=$m->name if 'Node' eq ref $m;
    $n=$n->name if 'Node' eq ref $n;
    ($m,$n)=($n,$m) if $n lt $m;
    next if defined $name2edge->{Edge->name($m,$n)};
    $self->add_nodes($m,$n);
    my($node_m,$node_n)=map {$self->name2node->{$_}} ($m,$n);
    my $edge=new Edge(-nodes=>[$node_m,$node_n]);
    $node_m->add_neighbor($node_n);
    $node_n->add_neighbor($node_m);
    push(@$edges,$edge);
    $name2edge->{$edge->name}=$edge;
  }
}
*add_edge=\&add_edges;

########################################
# represents one node of a graph
package Node;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS %AUTODB);
use strict;

@AUTO_ATTRIBUTES=qw(name neighbors);
%DEFAULTS=(neighbors=>[]);
%AUTODB;			# non-persistent!
Class::AutoClass::declare;

sub add_neighbor {
  my($self,$neighbor)=@_;
  push(@{$self->neighbors},$neighbor) unless $self==$neighbor;
}

########################################
# represents one edge of a graph
package Edge;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS %AUTODB);
# use Node;

@AUTO_ATTRIBUTES=qw(nodes);
%DEFAULTS=(nodes=>[]);
%AUTODB;			# non-persistent!
Class::AutoClass::declare;

sub _init_self {
  my($self,$class,$args)=@_;
  # return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  my $nodes=$self->nodes;
  my($m,$n)=@$nodes;
  $self->nodes([$n,$m]) if defined $m && defined $n && $n->name lt $m->name;
  my($mname,$nname)=map {$_->name} @{$self->nodes};
  $self->{name}="$mname<->$nname";
}
# spit out "m<->n". 
# can be called as object or class method. as class method, args should be node names
sub name {
  my $self=shift;
  my $name=ref $self? (@_? $self->{name}=$_[0]: $self->{name}): join('<->',@_);
  # $name
}
1;

