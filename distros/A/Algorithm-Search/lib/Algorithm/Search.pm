package Algorithm::Search;

$VERSION = '0.04';

use 5.006;
use strict;
use Carp;
use warnings;


#Copyright 2008 Arthur S Goldstein


sub continue_search {
  my $self = shift;
  my $parameters = shift;
  if (defined $parameters->{additional_steps}) {
    $self->{max_steps} += $parameters->{additional_steps};
    $self->{continue_search} = 1;
  }
  while ($self->{continue_search}) {
#print STDERR "Search step ".$self->{steps}."\n";
    if ($self->{steps} == $self->{max_steps}) {
      $self->{continue_search} = 0;
      $self->{too_many_steps} = 1;
    }
    elsif (&{$self->{stop_search}}
     ($self->{last_object}, $self->{steps}, $self->{last_path})) {
      $self->{continue_search} = 0;
    }
    else {
      &{$self->{search_step}}($self);
#      $self->{steps}++;
    }
  }
  return;
}

sub solution_found {
  my $self = shift;
  return ($self->{solutions_found} > 0);
}

sub solutions_found {
  my $self = shift;
  return $self->{solutions_found};
}

sub solution {
  my $self = shift;
  if ($#{$self->{solutions}} == -1) {
    return undef;
  }
  return $self->{solutions}->[0];
}

sub solutions {
  my $self = shift;
  return @{$self->{solutions}};
}

sub search_trace {
  my $self = shift;
  return $self->{trace};
}

sub path {
  my $self = shift;
  if ($#{$self->{paths}} == -1) {
    return undef;
  }
  return $self->{paths}->[0];
}

sub paths {
  my $self = shift;
  return @{$self->{paths}};
}

sub last_object {
  my $self = shift;
  return $self->{last_object};
}

sub completed {
  my $self = shift;
  return $self->{search_completed};
}

sub steps {
  my $self = shift;
  return $self->{steps};
}

sub first_search_step {
  my $self = shift;
  my $initial_cost = $self->{initial_cost};
#why doesn't below line work?
  #my $initial_position = $self->{last_object} = $self->{search_this}->copy;
  my $x_position = $self->{last_object} = $self->{search_this}->copy;
  my $initial_position = $x_position;
  #my $initial_position = $self->{last_object} = $self->{search_this};

  if ($self->{mark_solution}) {
    if ($initial_position->is_solution) {
      push @{$self->{paths}}, $self->{last_path} = [];
      push @{$self->{solutions}}, $initial_position;
      if (++$self->{solutions_found} == $self->{solutions_to_find}) {
        $self->{search_completed} = 1;
        $self->{continue_search} = 0;
      }
    }
  }

  my %path_values;
  my $value;
  if ($self->{value_function}) {
    $value = $initial_position->value;
    if ($self->{do_not_repeat_values}) {
      $self->{handled}->{$value} = 1;
    }
    $path_values{$value} = 1;
  }

  my $initial_commit;
  if ($self->{committing}) {
    $initial_commit = $initial_position->commit_level;
  }

  if ($self->{return_search_trace}) {
    push @{$self->{trace}}, {
     cost => $initial_cost,
     commit => $initial_commit,
     value_after => $value,
     value_before => undef,
     move => undef,
    };
  }

  $self->{queue} = [];
#print STDERR "tsize of queue is ".(scalar @{$self->{queue}})."\n";
  foreach my $move (reverse $initial_position->next_moves) {
#print STDERR "FAdded $move to queue\n";
    push @{$self->{queue}},
    [$initial_position, $move, [], \%path_values, $initial_cost,
     $initial_commit, $value];
  }
#print STDERR "set up queu \n";
#print STDERR "rsize of queue is ".(scalar @{$self->{queue}})."\n";
}

sub search_step {
  my $self = shift;

  if (!(scalar @{$self->{queue}})) {
    $self->{search_completed} = 1;
    $self->{continue_search} = 0;
    return;
  }

#print STDERR "size of queue is ".(scalar @{$self->{queue}})."\n";
  my ($position, $move, $path, $path_values, $cost, $commit, $previous_value) =
   @{shift @{$self->{queue}}};
  my $new_position;
  $new_position = $position->copy;
#print STDERR "recovered from queue cost $cost\n";

  my $new_cost = $new_position->move($move, $cost);
  $self->{steps}++;
#print STDERR "new cost is $new_cost\n";
  if (!defined $new_cost) {
    return;
  };

  if ($self->{cost_cannot_increase} && ($new_cost > $cost) && (defined $cost))
  {
    return;
  }

  $self->{last_object} = $new_position;
  my $new_path;
  $new_path = [@$path, $move];
  $self->{last_path} = $new_path;

  my $new_path_values;
  my $value;
  if ($self->{value_function}) {
     $value = $new_position->value;
    if ($path_values->{$value}) {
      return;
    }
    if ($self->{do_not_repeat_values}) {
      if ($self->{handled}->{$value}) {
        return;
      }
      $self->{handled}->{$value} = 1;
    }
    $new_path_values = {%$path_values};
    $new_path_values->{$value} = 1;
  }

  if ($self->{return_search_trace}) {
    push @{$self->{trace}}, {
     cost => $cost,
     commit => $commit,
     value_before => $previous_value,
     value_after => $value,
     move => $move,
    };
  }

  if ($self->{mark_solution}) {
    if ($new_position->is_solution) {
      push @{$self->{paths}}, $new_path;
      push @{$self->{solutions}}, $new_position;
      if (++$self->{solutions_found} == $self->{solutions_to_find}) {
        $self->{search_completed} = 1;
        $self->{continue_search} = 0;
      }
    }
  }

  if (scalar(@$new_path) == $self->{maximum_depth_minus_one}) {
    return;
  }

  my $new_commit;
  if ($self->{committing}) {
    $new_commit = $new_position->commit_level;
    if ($new_commit < $commit) {
      $self->{queue} = [];
    }
  }

  if ($self->{search_type} eq 'dfs') {
    foreach my $move (reverse $new_position->next_moves) {
      unshift @{$self->{queue}},
      [$new_position, $move, $new_path, $new_path_values, $new_cost,
       $new_commit, $value];
    }
  }
  elsif ($self->{search_type} eq 'bfs') {
    foreach my $move ($new_position->next_moves) {
      push @{$self->{queue}},
      [$new_position, $move, $new_path, $new_path_values, $new_cost,
       $new_commit, $value];
    }
  }
  elsif ($self->{search_type} eq 'cost') {
    my @moves = $new_position->next_moves;
    if (scalar(@moves)) {
      my ($l, $u) = (-1, scalar(@{$self->{queue}}));
      my $m;
      while ($u - $l > 1) {
        $m = $l + int (($u-$l)/2);
#print STDERR "m is $m and u is $u and nc is $new_cost cost is $cost ";
#print STDERR "4 is ";
#print STDERR $self->{queue}->[$m]->[4]."\n";
        if ($self->{queue}->[$m]->[4] > $new_cost) { #4 is cost
          $u = $m;
        }
        else {
          $l = $m;
        }
      }
      foreach my $move (reverse @moves) {
#print STDERR "adding to queue nc $new_cost\n";
        splice (@{$self->{queue}}, $u, 0,
         [$new_position, $move, $new_path, $new_path_values, $new_cost,
          $new_commit, $value]);
      }
    }
  }
  else {
    croak ("Unknown search type");
  }
}


sub rdfs_first_search_step {
  my $self = shift;
  my $search_this = $self->{search_this};
  $self->{last_object} = $search_this; #does not change
  $self->{cost} = $self->{initial_cost};
  if ($self->{committing}) {
    $self->{commit} = $search_this->commit_level;
  }
  if ($search_this->is_solution) {
    push @{$self->{paths}}, $self->{last_path} = [];
    if ($self->{preserve_solutions}) {
      push @{$self->{solutions}}, $search_this->copy;
    }
    if (++$self->{solutions_found} == $self->{solutions_to_find}) {
      $self->{search_completed} = 1;
      $self->{continue_search} = 0;
    }
  }
  $self->{next_move} = $search_this->move_after_given();
  my $value;
  if (!defined $self->{next_move}) {
    $self->{search_completed} = 1;
    $self->{continue_search} = 0;
  }
  else {
    $self->{moving_forward} = 1;
    $self->{path} = [];
    $self->{cost_list} = [];
    $self->{commit_list} = [];
    if ($self->{value_function}) {
      $value = $search_this->value;
      $self->{path_values} = {$value => 1};
      $self->{value_list} = [$value];
      if ($self->{do_not_repeat_values}) {
        $self->{handled}->{$value} = 1;
      }
    }
    push @{$self->{info}}, [$value, $self->{cost}, $self->{commit}];
  }
  if ($self->{return_search_trace}) {
    push @{$self->{trace}}, {
     cost => $self->{cost},
     commit => $self->{commit},
     value_before => undef,
     value_after => $value,
     move => undef,
    };
  }

}

sub forward_rdfs_search_step {
  my $self = shift;
  my $search_this = $self->{search_this};
  my $next_move = $self->{next_move};
#print STDERR "frdfs next move is $next_move\n";
  my $new_cost = $search_this->move($next_move);
  $self->{steps}++;
  if (!defined $new_cost) {
    $self->{moving_forward} = 0;
    return;
  }
  if (($self->{cost_cannot_increase}) && ($new_cost > $self->{cost})) {
#print STDERR "cost increased was ".$self->{cost}." to be $new_cost\n";
    $search_this->reverse_move($next_move);
    $self->{moving_forward} = 0;
    return;
  }

  my $value;
  if ($self->{value_function}) {
    $value = $search_this->value;
#print STDERR "considering vf on $value\n";
    if ($self->{do_not_repeat_values}) {
      if ($self->{handled}->{$value}) {
#print STDERR "handled already\n";
        $search_this->reverse_move($next_move);
        $self->{moving_forward} = 0;
        return;
      }
      $self->{handled}->{$value} = 1;
    }
    if ($self->{path_values}->{$value}) {
#print STDERR "repeating value\n";
      $search_this->reverse_move($next_move);
      $self->{moving_forward} = 0;
      return;
    }
  }
  my $new_commit;
  if ($self->{committing}) {
    $new_commit = $search_this->commit_level;
  }

  if ($self->{return_search_trace}) {
#use Data::Dumper;
#print STDERR "si ".Dumper($self->{info})."\n";
    push @{$self->{trace}}, {
     cost => $new_cost,
     commit => $new_commit,
     value_after => $value,
     value_before => $self->{info}->[-1]->[0],
     move => $next_move,
    };
  }

  if ($search_this->is_solution) {
    push @{$self->{paths}}, [@{$self->{path}}, $next_move];
    if ($self->{preserve_solutions}) {
      push @{$self->{solutions}}, $search_this->copy;
    }
    if (++$self->{solutions_found} == $self->{solutions_to_find}) {
      $self->{search_completed} = 1;
      $self->{continue_search} = 0;
    }
#      else {
#        $self->{last_path} = $self->{path} = [@{$self->{path}}];
#      }
  }


  if (scalar(@{$self->{path}}) == $self->{maximum_depth_minus_one}) {
#print STDERR "hit max depth ".$self->{maximum_depth}."\n";
    $search_this->reverse_move($next_move);
    $self->{moving_forward} = 0;
    return;
  }

  $self->{next_move} = $search_this->move_after_given();
  if (defined $self->{next_move}) {
    if ($self->{value_function}) {
      $self->{path_values}->{$value} = 1;
    }
    push @{$self->{path}}, $next_move;
    push @{$self->{info}}, [$value, $new_cost, $new_commit];
    $self->{cost} = $new_cost;
    $self->{commit} = $new_commit;
    return;
  }
  else {
    $self->{next_move} = $next_move;
    $search_this->reverse_move($next_move);
    $self->{moving_forward} = 0;
    return;
  }
}

sub backward_rdfs_search_step {
  my $self = shift;
  my $search_this = $self->{search_this};
  my $next_move = $search_this->move_after_given($self->{next_move});
  if (defined $next_move) {
#print STDERR "back Have new move\n";
    $self->{moving_forward} = 1;
    $self->{next_move} = $next_move;
    return;
  }
  if (scalar(@{$self->{path}}) == 0) {
    $self->{search_completed} = 1;
    $self->{continue_search} = 0;
    return;
  }
  else {
    my ($previous_value, $previous_cost, $previous_commit) =
     @{pop @{$self->{info}}};
    if ($self->{committing} && ($self->{commit} < $previous_commit)) {
      $self->{search_completed} = 1;
      $self->{continue_search} = 0;
      return;
    }
    $self->{cost} = $previous_cost;
    $self->{commit} = $previous_commit;
    if ($self->{value_function}) {
      $self->{path_values}->{$previous_value}--;
    }
    $self->{next_move} = pop @{$self->{path}};
    $search_this->reverse_move($self->{next_move});
  }
}

sub rdfs_search_step {
  my $self = shift;
  my $search_this = $self->{search_this};
  my $path_values = $self->{path_values};
  my $direction = $self->{direction};

#print STDERR "step ".$self->{steps}."\n";
  if ($self->{moving_forward}) {
    $self->forward_rdfs_search_step;
  }
  else {
    $self->backward_rdfs_search_step;
  }
}

sub search {
  my $self = shift;
  my $parameters = shift;
  $self->{search_this} = $parameters->{search_this};
  $self->{max_steps} = $parameters->{max_steps}
   || $self->{default_max_steps} || 20000;
  $self->{solutions_to_find} = 1;
  if (defined $parameters->{solutions_to_find}) {
    $self->{solutions_to_find} = $parameters->{solutions_to_find};
  }
#print STDERR "Start search\n";
  $self->{do_not_repeat_values} = $parameters->{do_not_repeat_values};
  $self->{maximum_depth} = $parameters->{maximum_depth};
  if (defined $parameters->{maximum_depth}) {
    $self->{maximum_depth_minus_one} = $parameters->{maximum_depth} - 1;
  }
  else {
    $self->{maximum_depth_minus_one} = -1;
  }
  $self->{stop_search} = $parameters->{stop_search} || sub {return 0};
  $self->{return_search_trace} = $parameters->{return_search_trace};
  my $no_value_function = $parameters->{no_value_function};
  $self->{initial_cost} = $parameters->{initial_cost};
  $self->{cost_cannot_increase} = $parameters->{cost_cannot_increase};

#copy might not be defined for rdfs, others it is required
  if (UNIVERSAL::can($self->{search_this},"copy")) {
    $self->{preserve_solutions} = 1;
  }
  else {
    $self->{preserve_solutions} = 0;
  }

  if (UNIVERSAL::can($self->{search_this},"is_solution")) {
    $self->{mark_solution} = 1;
  }
  else {
    $self->{mark_solution} = 0;
  }

  if (UNIVERSAL::can($self->{search_this},"value")) {
    $self->{value_function} = 1;
  }
  else {
    $self->{value_function} = 0;
  }
  if ($no_value_function) {
    $self->{value_function} = 0;
  }

  if (UNIVERSAL::can($self->{search_this},"commit_level")) {
    $self->{committing} = 1;
  }
  else {
    $self->{committing} = 0;
  }

  if (defined $parameters->{search_type}) {
    $self->{search_type} = $parameters->{search_type};
    if ($parameters->{search_type} eq 'dfs') {
      $self->{first_search_step} = \&first_search_step;
      $self->{search_step} = \&search_step;
    }
    elsif ($parameters->{search_type} eq 'bfs') {
      $self->{first_search_step} = \&first_search_step;
      $self->{search_step} = \&search_step;
    }
    elsif ($parameters->{search_type} eq 'cost') {
        $self->{first_search_step} = \&first_search_step;
        $self->{search_step} = \&search_step;
    }
    elsif ($parameters->{search_type} eq 'rdfs') {
      $self->{first_search_step} = \&rdfs_first_search_step;
      $self->{search_step} = \&rdfs_search_step;
    }
    else {
      die "Unknown search type ".$parameters->{search_type};
    }
  }
  else {
    $self->{first_search_step} = $self->{default_first_search_step};
    $self->{search_step} = $self->{default_search_step};
    $self->{search_type} = $self->{default_search_type};
  }
  $self->{handled} = {};
  $self->{move_list} = [undef];
  $self->{moving_forward} = 1;
  $self->{continue_search} = 1;
  $self->{search_completed} = 0;
  $self->{solutions_found} = 0;
  $self->{solutions} = [];
  $self->{paths} = [];
  $self->{trace} = [];
  &{$self->{first_search_step}}($self);
  $self->{steps} = 1;
  $self->continue_search;
}

sub new {
  my $type = shift;
  my $class = ref($type) || $type;
  my $parameters = shift;
  my $self = {};
  $self->{default_first_search_step} = \&first_search_step;
  $self->{default_search_type} = 'dfs';
  $self->{default_search_step} = \&search_step;
  bless $self, $class;
  return $self;
}


1;

__END__

=head1 NAME

Algorithm::Search - Module for traversing an object.

=head1 SYNOPSIS

  use Algorithm::Search;
  my $as = new Algorithm::Search();

  $as->search({ # Example parameters here are the default parameters
   search_this => $object_to_search, #no default
   search_type => 'dfs', # dfs, bfs, cost, or rdfs
   max_steps => 20000, # number of moves to look at
   maximum_depth => 0, # longest allowable path length if > 0
   solutions_to_find => 0, # search stops when number reached, 0 finds all
   do_not_repeat_values => 0, # only traverse position with value once
   cost_cannot_increase => 0, # whether or not moves can increase cost
   initial_cost => undef, # for cost based search
   return_search_trace => 0, # does $as->search_trace return array ref of moves
  });
  if (!$as->completed) {
    $as->continue_search({additional_steps => 300});
  }

  if ($as->solution_found) {
    @solutions = $as->solutions;
    @paths_to_solution = $as->paths;
  }

  $steps_taken = $search->steps_taken;


=head1 DESCRIPTION AND DEFINITIONS

A user provided traversable object starts in an initial position.
The traversable
object must have certain methods, such as 'move', described below.
This is passed into the search method via the 'search_this' parameter.

At any position, the object has a list of moves to new positions,
the list may be empty.

A position is a solution if the "is_solution" function returns true.

A traversal does not require that a solution be found or even looked for.
A search is a traversal that looks for a solution.

A path corresponds to a list of valid moves from the initial position.
The path values correspond to the list of values by the positions
the object moves along the path.

A move is valid if the move function returns a value.
The number of steps, is the number of calls to the move function.

A queue based traversal stores positions and paths on a queue, copying
the object before performing each move.

In depth first search (dfs), the next position to search is the
most recently placed on the queue.

In breadth first search (bfs), the next item to search is the least
recently placed on the queue.

In cost based search (cost) , the next item to search is the lowest
cost item on the queued, ties go to the most recently placed on the queue.
Cost based search with all the same costs behaves as depth first search.

A reversible depth first search (rdfs) traversal uses
reverse move to traverse paths with the search object.
A reversible traversal does not use a queue resulting in less memory
usage.  A reversible traversal is more complicated to set up and only
allows depth first search.

=head1 Methods Required in object being searched.

=head2 Common to all Searches

  sub move ($move, $cost)
   #required, return undef if illegal move else return cost

If the parameter cost_cannot_increase is set, any move which
would decrease the cost is disallowed.  The cost is the value
returned from the move method.

The search parameter initial_cost corresponds to where in the
queue the moves from the initial position belong.

  sub value #optional - used to pare down search, a value cannot
   #repeat on a search path, prevents loops in paths

If the parameter do_not_repeat_values is set, a value cannot
repeat any time in the search.  Presumably this would be done to
find a single solution and not be concerned about the paths.

  sub stop_search #optional - after every step, this procedure
   #is passed the current position, the number of steps,
   #and the path to the current position.  If it returns
   #a true value, the search stops.  Useful for tracing the search.

=head2 Depth First, Breadth First, and Cost Queue-Based Searches

  sub next_moves #required, list of moves from given object

  sub copy #required

  sub commit_level #optional - returns number, used to pare down search
  # if the commit level decreases, all moves in the queue are emptied
  # except for the current position

  sub move #return numeric value, the lower the value, the earlier the
   #moves from the position will be traversed.

=head2 Reversible Depth First Search (rdfs)

  sub move_after_given($previous_move) #required
   #if $previous_move is null, first move to try from position
   #else the next move after $previous move is returned, undef if no move

  sub reverse_move #required

  sub copy # If provided, will copy solutions to an array.

  sub commit_level #optional - returns number, used to pare down search
  # cannot reverse a move to a position with a higher commit level

=head1 Examples

There is a directory example included in the package.

=head2 Depth First Queue Based Search Example

  package traveller;

  $destination = '';
  %roads = (
   'Minneapolis' => ['St. Paul', 'Duluth'],
   'St. Paul' => ['Minneapolis', 'Madison'],
   'Madison' => ['Rockford', 'St. Paul', 'Chicago'],
   'Rockford' => ['Bloomington', 'Madison'],
   'Bloomington' => ['Champaign'],
   'Champaign' => ['Urbana', 'Chicago'],
   'Chicago' => ['Minneapolis', 'Urbana'],
   'Urbana' => [],
   'Duluth' => [],
   );

  sub new {return bless {}}
  sub next_moves {my $self = shift;
    return @{$roads{$self->{position}}}}
  sub move {my $self = shift; $self->{position} = shift; return 0;}
  sub value {my $self = shift; return $self->{position}}
  sub copy {my $self = shift; my $copy = $self->new;
   $copy->move($self->{position}); return $copy;};
  sub is_solution {my $self = shift;
     return $self->{position} eq $destination;}
  sub set_destination {my $self = shift; $destination = shift;}

  package main;
  use Algorithm::Search;
  my $driver = new traveller;
  my $travel_search = new Algorithm::Search();

  $driver->move('Minneapolis'); #start out in Minneapolis
  $driver->set_destination('Urbana');
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
  });
  my $full_path;
  if ($travel_search->solution_found) { #should be true, path to Urbana
    foreach my $path ($travel_search->paths) {
      $full_path .= join("..", @{$path})."\n";
    }
  }

  #$full_path should contain string:
St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana


=head2 Cost Based Search Example

  package traveller;
  %roads = (
   'Minneapolis' => ['St. Paul', 'Duluth'],
   'St. Paul' => ['Minneapolis', 'Madison'],
   'Madison' => ['Rockford', 'St. Paul', 'Chicago'],
   'Rockford' => ['Bloomington', 'Madison'],
   'Bloomington' => ['Champaign'],
   'Champaign' => ['Urbana', 'Chicago'],
   'Chicago' => ['Minneapolis', 'Urbana'],
   'Urbana' => [],
   'Duluth' => ['Chicago'],
   );
  %distance_to_urbana = (
   'Minneapolis' => 515,
   'St. Paul' => 505,
   'Madison' => 252,
   'Rockford' => 185,
   'Bloomington' => 56,
   'Champaign' => 2,
   'Chicago' => 140,
   'Urbana' => 0,
   'Duluth' => 575,
  );

  sub distance_to_urbana {
    my $self = shift;
    return $distance_to_urbana{$self->{position}};
  }
  sub new {return bless {}}
  sub next_moves {my $self = shift;
    return @{$roads{$self->{position}}}}
  sub move {my $self = shift; $self->{position} = shift;
     return $distance_to_urbana{$self->{position}};}
  sub value {my $self = shift; return $self->{position}}
  sub copy {my $self = shift; my $copy = $self->new;
   $copy->move($self->{position}); return $copy;};
  sub is_solution {my $self = shift;
     return $self->{position} eq 'Urbana';}

  package main;
  use Algorithm::Search;
  my $driver = new traveller;
  my $travel_search = new Algorithm::Search();

  $driver->move('Minneapolis');
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   search_type => 'cost',
   initial_cost => $driver->distance_to_urbana,
   maximum_depth => 8, #if 7 then only 3 paths will be returned
  });

  $full_path = '';
  foreach my $path ($travel_search->paths) {
    $full_path .= join("..", @{$path})."\n";
  }
  # $full_path should contain:
St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
Duluth..Chicago..Urbana

=head2 Reversible (Depth First) Search Example

  package r_traveller;

  %roads = (
   'Minneapolis' => ['St. Paul', 'Duluth'],
   'St. Paul' => ['Minneapolis', 'Madison'],
   'Madison' => ['Rockford', 'St. Paul', 'Chicago'],
   'Rockford' => ['Bloomington', 'Madison'],
   'Bloomington' => ['Champaign'],
   'Champaign' => ['Urbana', 'Chicago'],
   'Chicago' => ['Minneapolis', 'Urbana'],
   'Urbana' => [],
   'Duluth' => [],
   );

  sub new {return bless {}}
  sub move_after_given {
    my $self = shift;
    my $previous = shift;
    my $move_count = 0;
    if ($previous) {
      $move_count = $previous->[2] + 1;
    }
    my $city = $self->{position};
    if (scalar(@{$roads{$city}}) > $move_count) {
      return [$self->{position}, $roads{$city}->[$move_count], $move_count]
    }
    else {
      return undef;
    }
  }
  sub reverse_move {my ($self, $move) = @_; $self->{position} = $move->[0];}
  sub move {my ($self, $move) = @_; $self->{position} = $move->[1]; return 0}
  sub value {my $self = shift; return $self->{position}}
  sub is_solution {my $self = shift;
     return $self->{position} eq 'Urbana';}

  package main;
  use Algorithm::Search;
  my $r_driver = new r_traveller;
  $travel_search = new Algorithm::Search();

  $r_driver->move([undef, 'Minneapolis']); #start out in Minneapolis
  $travel_search->search({
   search_this => $r_driver,
   search_type => 'rdfs',
   solutions_to_find => 0,
  });
  $full_path .= "";
  foreach $path ($travel_search->paths) {
    foreach $move (@$path) {
      $full_path .= " ".$move->[0]." ";
    }
    $full_path .= "\n";
  }
  #$full_path should contain:
 Minneapolis  St. Paul  Madison  Rockford  Bloomington  Champaign 
 Minneapolis  St. Paul  Madison  Rockford  Bloomington  Champaign  Chicago 
 Minneapolis  St. Paul  Madison  Chicago 

=head1 AUTHOR

Arthur Goldstein , E<lt>arthur@acm.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Arthur Goldstein

=head1 BUGS

Please email in bug reports.

=head1 TO DO AND FUTURE POSSIBLE CHANGES

Test cases may take too long, can make faster.

Might want a value function for the moves, this might be of use in the
trace.

=head1 SEE ALSO

Any reference on depth/first search and searching in general.

=cut
