# $Id: Graph.pm,v 1.12 2003/10/05 09:34:24 clajac Exp $

package CPANXR::Visualize::Graph;
use CPANXR::Database;
use CPANXR::Parser qw(:constants);
use GraphViz;
use strict;

sub none {
  my $graph = GraphViz->new();
  $graph->add_node('Don\'t know\nwhat to do!');
  return $graph;
}

# IS-A relationships
sub class {
  my ($self, $class) = @_;

  $self = bless { checked => {} }, $self;

  my $graph = GraphViz->new(
			    width => 6,
			    height => 6,
			    directed => 1,
			    rankdir => 1,
			   );

  my $symbol = CPANXR::Database->select_symbol($class)->[0]->[0];
  $graph->add_node($class, label => $symbol, shape => 'rect');

  $self->_class_subclasses($graph, $class);

  return $graph;
}

sub _class_subclasses {
  my ($self, $graph, $parent) = @_;
  
  return if(exists $self->{checked}->{$parent});

  my $sub = CPANXR::Database->select_connections(symbol_id => $parent, limit_types => [CONN_ISA]);

  for (@$sub) {
    my $symbol = CPANXR::Database->select_symbol($_->[8]);
    $graph->add_node($_->[8], label => $symbol->[0]->[0], shape => 'rect');
    $graph->add_edge($parent => $_->[8], dir => 'back', label => 'is-a');
    $self->_class_subclasses($graph, $_->[8]);
  }

  1;
}

# Files
sub file {
  my ($self, $file_id) = @_;

  my $graph = GraphViz->new(
			    width => 6,
			    height => 6,
			    directed => 1,
			    rankdir => 1,
			   );

  my $result = CPANXR::Database->select_connections(file_id => $file_id);

  return $graph unless @$result;

  my $file = $result->[0]->[4];
 
  my %sym_list = map { $_->[0] => $_->[1] } grep { $_->[7] != CONN_DECL } @$result;
  my %added;
  my $cluster = _file_get_cluster($result->[0]->[9]);
  $file =~ s/^$cluster\/// if $cluster;

  $graph->add_node($file, shape => 'rect', style=>'filled', fillcolor => '#eeeeee', URL => "show?id=$result->[0]->[5]", cluster => $cluster);

  #  Packages
  {
    my %packages = map { $_->[1] => $_->[0] } grep { $_->[7] == CONN_PACKAGE } @$result;
    while (my ($name, $id) = each %packages) {
      my %sub = map { $_->[1] => 1 } grep { $_->[7] == CONN_DECL && $_->[6] == $id } @$result;
      $graph->add_node($id, label => [$name, join('\n', keys %sub)], URL => "find?symbol=$id", style => 'filled', fillcolor => '#ffffcc');
      $graph->add_edge($file => $id, label => 'declares');
      $added{$id} = 1;

      # Find users
      my $users = CPANXR::Database->select_connections(package_id => $id);
      my %files = map { $_->[4] => [$_->[5], $_->[9]] } @$users;

      for my $user_file (keys %files) {
	my $cluster = _file_get_cluster($files{$user_file}->[1]);
	$user_file =~ s/^$cluster\///;
	next if $user_file eq $file;
	my $url = "show?id=$files{$user_file}->[0]";

	$graph->add_node($user_file, shape => 'rect', style => 'filled', fillcolor => '#eeeeee', URL => $url, cluster => $cluster);
	$graph->add_edge($user_file => $id, label => 'references', URL => $url);
      }
    }
  }

  # Includes
  {
    my %includes = map { $_->[1] => $_->[0] } grep { $_->[7] == CONN_INCLUDE } @$result;
    while (my ($name, $id) = each %includes) {
      my %ref = map { $_->[1] => 1 } grep { $_->[6] == $id } @$result;
      my %attr;
      
      if (%ref && $name !~ /^base|vars$/) {
	$attr{label} = [$name, join('\n', keys %ref)];
      } else {
	$attr{label} = $name;
	$attr{shape} = 'rect';
      }
      $graph->add_node($id, %attr, URL => "find?symbol=$id");
      $added{$id} = 1;
    }
  }

  # edge
  {
    my %link;
    for my $ref (@$result) {
      my $url = "show?id=" . $file_id . "&hl=" . $ref->[2] . "#l" . $ref->[2];
      if ($ref->[7] == CONN_ISA) {
	unless ($added{$ref->[0]}) {
	  $graph->add_node($ref->[0], shape => 'rect', label => $sym_list{$ref->[0]});
	  $added{$ref->[0]} = 1;
	}

	$graph->add_edge($ref->[0] => $ref->[8], label => 'is-a', URL => $url);
      } elsif ($ref->[7] == CONN_INCLUDE) {
	next if exists $link{"$ref->[8]:$ref->[0]"};
	unless ($added{$ref->[8]}) {
	  $graph->add_node($ref->[8], shape => 'rect', label => $sym_list{$ref->[8]});
	  $added{$ref->[8]} = 1;
	}

	$graph->add_edge($ref->[8] => $ref->[0], label => 'uses', URL => $url);
	$link{"$ref->[8]:$ref->[0]"} = 1;
      }
    }
  }

  return $graph;
}

my %Clusters;
sub _file_get_cluster {
  my $id = shift;
  return $Clusters{$id} if exists $Clusters{$id};
  my $dist = CPANXR::Database->select_distributions(id => $id);
  if (@$dist) {
    $Clusters{$dist->[0]->[0]} = $dist->[0]->[1];
    return $dist->[0]->[1];
  }

  return "";
}

# Subroutine flow
sub subroutine {
  my ($self, $id) = @_;

  my ($sub_id, $pkg_id) = split/_/,$id,2;

  $self = bless { checked => {}, nodes => {} }, $self;

  my $graph = GraphViz->new(
			    width => 6,
			    height => 6,
			    directed => 1,
			    rankdir => 1,
			   );

  my $sub_name = CPANXR::Database->select_symbol($sub_id)->[0]->[0];
  my $pkg_name = CPANXR::Database->select_symbol($pkg_id)->[0]->[0];

  # Add from node
  $graph->add_node($sub_id,
		   label => $sub_name, 
		   cluster => $pkg_name, 
		   shape => 'rect',
		   style => 'filled', fillcolor => '#ffffcc');

  $self->_subroutine_calls($graph, $sub_id, $pkg_id);
  return $graph;
}

sub _subroutine_calls {
  my ($self, $graph, $sub_id, $pkg_id) = @_;

  return if(exists $self->{checked}->{"${sub_id}:${pkg_id}"});
  return unless $sub_id;
  return unless $pkg_id;

  $self->{checked}->{"${sub_id}:${pkg_id}"} = 1;
  # Get calls
  my $calls = CPANXR::Database->select_connections(caller_id => $pkg_id, caller_sub_id => $sub_id);

  for my $call (@$calls) {
    my $url = "graph?sub=" . $call->[0] . "_" . ($call->[6] || $call->[8]);

    my $sub_call_pkg_name = CPANXR::Database->select_symbol($call->[6] || $call->[8])->[0]->[0];
    $graph->add_node($call->[0], label => $call->[1], shape => 'rect', cluster => $sub_call_pkg_name, URL => $url);
    unless(exists $self->{nodes}->{"${sub_id}:$call->[0]"}) {
      $graph->add_edge($sub_id => $call->[0]);
      $self->{nodes}->{"${sub_id}:$call->[0]"} = 1;
      $self->_subroutine_calls($graph, $call->[0], $call->[6] || $call->[8]);
    }
  }  
}

1;
