package graphUtil;
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbUtil;
use Exporter();

our @ISA=qw(Exporter);
our @EXPORT=(@autodbUtil::EXPORT,
	     qw($class2colls $class2transients $coll2keys label %test_args max_allowed_packet_ok
                chain star binary_tree ternary_tree cycle clique cone_graph grid torus
	     ));
# class2colls for all classes in graph tests
our $class2colls=
  {Graph_010=>[qw(Graph_010)],
   Node=>[],
   Edge=>[],
   Graph_020=>[qw(Graph_020)],
  };

# coll2keys for all collections in graph tests
our $coll2keys=
  {Graph_010=>[[qw(id name)],[]],
   Graph_020=>[[qw(id name)],[]],
  };

# class2transients for all collections in graph tests
our $class2transients=
  {Graph_010=>[qw(name2node name2edge)]};

# label sub for all graph 'TestObject' tests
sub label {
  my $test=shift;
  my $object=$test->current_object;
#  $object->id.' '.$object->name if $object;
  (UNIVERSAL::can($object,'name')? $object->name:
   (UNIVERSAL::can($object,'desc')? $object->desc:
    (UNIVERSAL::can($object,'id')? $object->id: '')));
}

our %test_args=(class2colls=>$class2colls,class2transients=>$class2transients,
		coll2keys=>$coll2keys,label=>\&label);


# some of these graphs are very big. make sure max_allowed_packet big enough
# value used here (2 MB) determined empirically. may have to change if graphs change!!
# NG 10-03-08: turns out that changing max_allowed_packet has no effect despite
#              what the MySQL documentations says...
sub max_allowed_packet_ok {
  my($name,$max_allowed_packet)=
    dbh->selectrow_array(qq(SHOW VARIABLES LIKE 'max_allowed_packet'));
  diag "max_allowed_packet=$max_allowed_packet";
  my $min=2*1024*1024;
  unless ($max_allowed_packet>=$min) {
    # dbh->do(qq(SET max_allowed_packet=$min));
    # ($name,$max_allowed_packet)=
    #    dbh->selectrow_array(qq(SHOW VARIABLES LIKE 'max_allowed_packet'));
    #  diag "max_allowed_packet after set=$max_allowed_packet";
    # return 0 unless $max_allowed_packet>=$min; # fail if it didn't work...
#   }
    diag "max_allowed_packet=$max_allowed_packet too small. must be >= $min";
    return 0;
  }
  $max_allowed_packet;
}

################################################################################
# Functions below here are for making test graphs
################################################################################
use Hash::AutoHash::Args;

my %DEFAULT_ARGS=
  (CIRCUMFERENCE=>100,
   CONE_SIZE=>10,
   HEIGHT=>10,
   WIDTH=>10,
   ARITY=>2,
   DEPTH=>3,
   NODES=>100,
  );

sub binary_tree {regular_tree(@_,-arity=>2)}
sub ternary_tree {regular_tree(@_,-arity=>3)}

sub chain {
  my $args=new Hash::AutoHash::Args(@_);
  my $chain=$args->graph;
  my($nodes)=get_args($args,qw(nodes));
  if ($nodes) {
    for (my $new=1; $new<$nodes; $new++) {
      $chain->add_edge($new-1,$new);
    }}
  $chain;
}
sub regular_tree {
  my $args=new Hash::AutoHash::Args(@_);
  my $tree=$args->graph;
  my($depth,$arity,$root)=get_args($args,qw(depth arity root));
  defined $root or $root=0;
  $tree->add_node($root);
  if ($depth>0) {
    for (my $i=0; $i<$arity; $i++) {
      my $child="$root/$i";
      $tree->add_edge($root,$child);
      regular_tree(graph=>$tree,depth=>$depth-1,arity=>$arity,root=>$child);
    }
  }
  $tree;
}

sub star {
  my $args=new Hash::AutoHash::Args(@_);
  my $star=$args->graph;
  my($nodes)=get_args($args,qw(nodes));
  if ($nodes) {
    my $center=0;
    for (my $point=1; $point<$nodes; $point++) {
      $star->add_edge($center,$point);
    }}
  $star
}
sub cycle {
  my $args=new Hash::AutoHash::Args(@_);
  my $graph=$args->graph;
  my($nodes)=get_args($args,qw(nodes));
  # make simple cycle
  for (my $i=1; $i<$nodes; $i++) {
    $graph->add_edge($i-1,$i);
  }
  $graph->add_edge($nodes-1,0);
  $graph;
}
sub clique {
  my $args=new Hash::AutoHash::Args(@_);
  my $graph=$args->graph;
  my($nodes)=get_args($args,qw(nodes));
  for (my $i=0; $i<$nodes-1; $i++) {
    for (my $j=$i+1; $j<$nodes; $j++) {
      $graph->add_edge($i,$j);
    }
  }
  $graph;
}
sub cone_graph {
  my $args=new Hash::AutoHash::Args(@_);
  my $graph=$args->graph;
  my($cone_size)=get_args($args,qw(cone_size));
  # make $cone_size simple cycles of sizes 1..$cone_size
  for (my $i=0; $i<$cone_size; $i++) {
    my $circumference=$i+1;
    # make simple cycle
    for (my $j=1; $j<$circumference; $j++) {
      $graph->add_edge($i.'/'.($j-1),"$i/$j");
    }
    $graph->add_edge($i.'/'.($circumference-1),"$i/0");
  }
  # add edges between cycles
  for (my $i=0; $i<$cone_size-2; $i++) {
    for (my $j=$i+1; $j<$cone_size; $j++) {
      $graph->add_edge("$i/0","$j/0");
    }}
  $graph;
}
sub grid {
  my $args=new Hash::AutoHash::Args(@_);
  my $graph=$args->graph;
  my($height,$width)=get_args($args,qw(height width));
  for (my $i=0; $i<$height; $i++) {
    for (my $j=0; $j<$width; $j++) {
      my $node=grid_node($i,$j);
      $graph->add_node($node);
      $graph->add_edge(grid_node($i-1,$j),$node) if $i>0; # down
      $graph->add_edge(grid_node($i,$j-1),$node) if $j>0; # right
    }}
  $graph;
}
sub torus {
  my $args=new Hash::AutoHash::Args(@_);
  my $graph=$args->graph;
  my($height,$width)=get_args($args,qw(height width));
  for (my $i=0; $i<$height; $i++) {
    for (my $j=0; $j<$width; $j++) {
      my $node=grid_node($i,$j);
      $graph->add_node($node);
      $graph->add_edge(grid_node($i-1,$j),$node) if $i>0; # down
      $graph->add_edge(grid_node($i,$j-1),$node) if $j>0; # right
    }}
  # add wrapround edges, making grid a torus
  if ($width>1) {
    for (my $i=0; $i<$height; $i++) {
      $graph->add_edge(grid_node($i,$width-1),grid_node($i,0));
    }}
  if ($height>1) {
    for (my $j=0; $j<$width; $j++) {
      $graph->add_edge(grid_node($height-1,$j),grid_node(0,$j));
    }}
  $graph;
}
sub grid_node {my($i,$j)=@_; $j=$i unless defined $j; "$i/$j";}

# probably not needed with new Hash::AutoHash::Args
sub get_args {
  my $args=shift;
  my @args;
  for my $keyword (@_) {
    my $arg=$args->$keyword;
    defined $arg or $arg=$DEFAULT_ARGS{uc $keyword};
    push(@args,$arg);
  }
  wantarray? @args: $args[0];
}
*get_arg=\&get_args;
1;
