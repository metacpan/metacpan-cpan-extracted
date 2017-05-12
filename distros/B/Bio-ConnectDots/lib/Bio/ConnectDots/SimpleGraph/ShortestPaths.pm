package Bio::ConnectDots::SimpleGraph::ShortestPaths;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use Class::AutoClass;
use Bio::ConnectDots::SimpleGraph;
use strict;
@ISA = qw(Class::AutoClass); # AutoClass must be first!!

@AUTO_ATTRIBUTES=qw(graph);
@OTHER_ATTRIBUTES=qw();
%SYNONYMS=();
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);

# Floyd-Warshall All Pairs Shortest Paths algorithm
# adapted from http://www.comp.nus.edu.sg/~stevenha/programming/prog_graph6.html

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
}

my($dist,$path);		# global variables in algorithm

sub paths {
  my($self,$graph)=@_;
  $graph or $graph=$self->graph;
  return unless $graph;
  # initialization
  my $nodes=$graph->nodes;
  $dist={};
  $path={};
  for (my $i=0; $i<@$nodes; $i++) { # start from i
    my $node0=$nodes->[$i];
    for (my $j=0; $j<@$nodes; $j++) { # end at j
      my $node1=$nodes->[$j];
      if ($i==$j) {
	$dist->{$i,$j}=0;
	next;
      }
      next unless $graph->has_edge($node0,$node1);
      $dist->{$i,$j}=1;
      $path->{$i,$j}=[$i,$j];
    }
  }
  # compute paths
  for (my $k=0; $k<@$nodes; $k++) {        # k is intermediate point
    for (my $i=0; $i<@$nodes-1; $i++) {    # start from i
      next unless defined $dist->{$i,$k};
      for (my $j=$i+1; $j<@$nodes; $j++) { # NG 04-02-10 added optimization
#      for (my $j=0; $j<@$nodes; $j++) { # end at j
	next unless defined $dist->{$k,$j};
	# path i..k..j exists -- is it shorter than what we already have?
	if (!defined $dist->{$i,$j} || $dist->{$i,$k}+$dist->{$k,$j} < $dist->{$i,$j}) {
	  $dist->{$i,$j}=$dist->{$i,$k}+$dist->{$k,$j};
	  $path->{$i,$j}=join_paths($i,$k,$j);
#	  # NG 04-02-10 next two lines needed for optimization above
	  $dist->{$j,$i}=$dist->{$i,$j};
	  $path->{$j,$i}=[reverse @{$path->{$i,$j}}];
	}
      }
    }
  }
  # convert node indices (i,j,..) into nodes
  my $paths={};
  for (my $i=0; $i<@$nodes-1; $i++) {    # start from i
    my $nodei=$nodes->[$i];
    for (my $j=$i+1; $j<@$nodes; $j++) { # end at j
      my $p=$path->{$i,$j};
      my $nodej=$nodes->[$j];
      my $path_nodes=[map {$nodes->[$_]} @$p];
      if ("$nodei" lt "$nodej") {
	$paths->{$nodei,$nodej}=$path_nodes;
      } else {
	$paths->{$nodej,$nodei}=[reverse @$path_nodes];
      }
    }
  }
  $paths;
}

sub join_paths {
  my($i,$k,$j)=@_;
  my $path0=$path->{$i,$k} || [];
  my $path1=$path->{$k,$j} || [];
  my $last0=@$path0-1;
  my $last1=@$path1-1;
  my $result=[];
  @$result=(@$path0[0..$last0-1],$k,@$path1[1..$last1]);
  $path->{$i,$j}=$result;
}



1;
