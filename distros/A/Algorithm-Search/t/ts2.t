#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein
use Test::More tests => 35;

  package traveller;
#only to Urbana

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

  $driver->move('Minneapolis'); #start out in Minneapolis
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
  });
  my $full_path;
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"Duluth..Chicago..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
", 'ts2 minneapolis to urbana paths');

  $travel_search->search({search_this => $driver,
   solutions_to_find => 2
  });
#print "sf \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"Duluth..Chicago..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
", 'ts2 limit 2');


  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   maximum_depth => 5
  });
#print "md \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"Duluth..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
", 'ts2 max depth dfs');


  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   do_not_repeat_values => 1
  });
#print "dnr \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"Duluth..Chicago..Urbana
",
'ts2 dfs no repeat values');


  $driver->move('Duluth'); #start out in Duluth
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
  });
  $full_path = '';
  if ($travel_search->solution_found) { #should be false, no path to Urbana
    $full_path = 'x';
#print "found path from Duluth to Urbana\n";
  }
  is ($full_path, 'x', 'ts2 from duluth dfs');


  $driver->move('Minneapolis'); #start out in Minneapolis
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   cost_cannot_increase => 1,
   initial_cost => $driver->distance_to_urbana,
  });
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Chicago..Urbana
", 'ts2 nd minneapolis to urbana paths');

  $travel_search->search({search_this => $driver,
   solutions_to_find => 2,
   cost_cannot_increase => 1,
   initial_cost => $driver->distance_to_urbana,
  });
#print "sf \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Chicago..Urbana
", 'ts2 d limit 2');


  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   maximum_depth => 5,
   cost_cannot_increase => 1,
   initial_cost => $driver->distance_to_urbana,
  });
#print "md \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Chicago..Urbana
", 'ts2 xnd max depth dfs');


  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   do_not_repeat_values => 1,
   cost_cannot_increase => 1,
   initial_cost => $driver->distance_to_urbana,
  });
#print "dnr \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
",
'ts2 nd dfs no repeat values');


  $driver->move('Duluth'); #start out in Duluth
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   cost_cannot_increase => 1,
   initial_cost => $driver->distance_to_urbana,
  });
  $full_path = '';
  if ($travel_search->solution_found) { #should be false, no path to Urbana
    $full_path = 'x';
#print "found path from Duluth to Urbana\n";
  }
  is ($full_path, 'x', 'ts2 nd from duluth dfs');

  $driver->move('Minneapolis'); #start out in Minneapolis
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   maximum_depth => 8,
   no_value_function => 1,
  });
#print "md \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"Duluth..Chicago..Minneapolis..St. Paul..Madison..Chicago..Urbana
Duluth..Chicago..Minneapolis..Duluth..Chicago..Urbana
Duluth..Chicago..Urbana
St. Paul..Minneapolis..St. Paul..Minneapolis..Duluth..Chicago..Urbana
St. Paul..Minneapolis..St. Paul..Madison..Chicago..Urbana
St. Paul..Minneapolis..Duluth..Chicago..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
St. Paul..Madison..Rockford..Madison..Chicago..Urbana
St. Paul..Madison..St. Paul..Minneapolis..Duluth..Chicago..Urbana
St. Paul..Madison..St. Paul..Madison..Chicago..Urbana
St. Paul..Madison..Chicago..Minneapolis..Duluth..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
", 'ts2 nd dfs distance can increase, no value function');



# as bfs

  $driver->move('Minneapolis'); #start out in Minneapolis
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   search_type => 'bfs',
  });
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"Duluth..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
", 'ts2 bfs minneapolis to urbana paths');

  $travel_search->search({search_this => $driver,
   search_type => 'bfs',
   solutions_to_find => 2
  });
#print "sf \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"Duluth..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
", 'ts2 bfs limit 2');


  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   search_type => 'bfs',
   maximum_depth => 5
  });
#print "md \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"Duluth..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
", 'ts2 bfs max depth');


  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   search_type => 'bfs',
   do_not_repeat_values => 1
  });
#print "dnr \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"Duluth..Chicago..Urbana
",
'ts2 bfs no repeat values');


  $driver->move('Duluth'); #start out in Duluth
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   search_type => 'bfs',
  });
  $full_path = '';
  if ($travel_search->solution_found) { #should be false, no path to Urbana
    $full_path = 'x';
#print "found path from Duluth to Urbana\n";
  }
  is ($full_path, 'x', 'ts2 from duluth bfs');


  $driver->move('Minneapolis'); #start out in Minneapolis
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   search_type => 'bfs',
   cost_cannot_increase => 1,
   initial_cost => $driver->distance_to_urbana,
  });
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Chicago..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
", 'ts2 bfs nd minneapolis to urbana paths');

  $travel_search->search({search_this => $driver,
   search_type => 'bfs',
   solutions_to_find => 2,
   cost_cannot_increase => 1,
   initial_cost => $driver->distance_to_urbana,
  });
#print "sf \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Chicago..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
", 'ts2 bfs nd limit 2');

  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   search_type => 'bfs',
   maximum_depth => 5,
   cost_cannot_increase => 1,
   initial_cost => $driver->distance_to_urbana,
  });
#print "md \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Chicago..Urbana
", 'ts2 nd max depth bfs');


  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   search_type => 'bfs',
   do_not_repeat_values => 1,
   cost_cannot_increase => 1,
   initial_cost => $driver->distance_to_urbana,
  });
#print "dnr \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Chicago..Urbana
",
'ts2 nd bfs no repeat values');


  $driver->move('Duluth'); #start out in Duluth
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   search_type => 'bfs',
  });
  $full_path = '';
  if ($travel_search->solution_found) { #should be false, no path to Urbana
    $full_path = 'x';
#print "found path from Duluth to Urbana\n";
  }
  is ($full_path, 'x', 'ts2 nd from duluth bfs');

  $driver->move('Minneapolis'); #start out in Minneapolis
  $travel_search->search({search_this => $driver,
   search_type => 'bfs',
   maximum_depth => 8,
   no_value_function => 1,
   solutions_to_find => 0,
  });
#print "md \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"Duluth..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
St. Paul..Minneapolis..Duluth..Chicago..Urbana
Duluth..Chicago..Minneapolis..Duluth..Chicago..Urbana
St. Paul..Minneapolis..St. Paul..Madison..Chicago..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Madison..Chicago..Urbana
St. Paul..Madison..St. Paul..Madison..Chicago..Urbana
Duluth..Chicago..Minneapolis..St. Paul..Madison..Chicago..Urbana
St. Paul..Minneapolis..St. Paul..Minneapolis..Duluth..Chicago..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
St. Paul..Madison..St. Paul..Minneapolis..Duluth..Chicago..Urbana
St. Paul..Madison..Chicago..Minneapolis..Duluth..Chicago..Urbana
", 'ts2 nd bfs distance can increase, no value function');



# as cost

  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   search_type => 'cost',
   initial_cost => $driver->distance_to_urbana,
   maximum_depth => 8,
  });

  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
Duluth..Chicago..Urbana
", 'ts2 nd cost distance can increase, max depth');

  $driver->move('Minneapolis'); #start out in Minneapolis
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   search_type => 'cost',
   initial_cost => $driver->distance_to_urbana,
  });
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
Duluth..Chicago..Urbana
", 'ts2 cost minneapolis to urbana paths');

  $travel_search->search({search_this => $driver,
   search_type => 'cost',
   initial_cost => $driver->distance_to_urbana,
   solutions_to_find => 2,
  });
#print "sf \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
", 'ts2 cost limit 2');


  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   search_type => 'cost',
   initial_cost => $driver->distance_to_urbana,
   maximum_depth => 5,
   return_search_trace => 1,
  });
#print "md \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Chicago..Urbana
Duluth..Chicago..Urbana
", 'ts2 cost max depth');

#use Data::Dumper;
#print STDERR "q: ".Dumper($travel_search->search_trace)."\n";
 is_deeply($travel_search->search_trace,
   [
          {
            'commit' => undef,
            'cost' => 515,
            'move' => undef,
            'value_before' => undef,
            'value_after' => 'Minneapolis'
          },
          {
            'commit' => undef,
            'cost' => 515,
            'move' => 'Duluth',
            'value_before' => 'Minneapolis',
            'value_after' => 'Duluth'
          },
          {
            'commit' => undef,
            'cost' => 515,
            'move' => 'St. Paul',
            'value_before' => 'Minneapolis',
            'value_after' => 'St. Paul'
          },
          {
            'commit' => undef,
            'cost' => 505,
            'move' => 'Madison',
            'value_before' => 'St. Paul',
            'value_after' => 'Madison'
          },
          {
            'commit' => undef,
            'cost' => 252,
            'move' => 'Rockford',
            'value_before' => 'Madison',
            'value_after' => 'Rockford'
          },
          {
            'commit' => undef,
            'cost' => 185,
            'move' => 'Bloomington',
            'value_before' => 'Rockford',
            'value_after' => 'Bloomington'
          },
          {
            'commit' => undef,
            'cost' => 252,
            'move' => 'Chicago',
            'value_before' => 'Madison',
            'value_after' => 'Chicago'
          },
          {
            'commit' => undef,
            'cost' => 140,
            'move' => 'Urbana',
            'value_before' => 'Chicago',
            'value_after' => 'Urbana'
          },
          {
            'commit' => undef,
            'cost' => 575,
            'move' => 'Chicago',
            'value_before' => 'Duluth',
            'value_after' => 'Chicago'
          },
          {
            'commit' => undef,
            'cost' => 140,
            'move' => 'Urbana',
            'value_before' => 'Chicago',
            'value_after' => 'Urbana'
          }
        ],
  'cost based max depth search trace');

  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   search_type => 'cost',
   initial_cost => $driver->distance_to_urbana,
   do_not_repeat_values => 1,
  });
#print "dnr \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
",
'ts2 cost no repeat values');


  $driver->move('Duluth'); #start out in Duluth
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   search_type => 'cost',
   initial_cost => $driver->distance_to_urbana,
  });
  $full_path = '';
  if ($travel_search->solution_found) { #should be false, no path to Urbana
    $full_path = 'x';
#print "found path from Duluth to Urbana\n";
  }
  is ($full_path, 'x', 'ts2 from duluth cost');


  $driver->move('Minneapolis'); #start out in Minneapolis
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   search_type => 'cost',
   cost_cannot_increase => 1,
   initial_cost => $driver->distance_to_urbana,
  });
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Chicago..Urbana
", 'ts2 cost nd minneapolis to urbana paths');

  $travel_search->search({search_this => $driver,
   search_type => 'cost',
   solutions_to_find => 2,
   cost_cannot_increase => 1,
   initial_cost => $driver->distance_to_urbana,
  });
#print "sf \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Chicago..Urbana
", 'ts2 cost nd limit 2');

  $travel_search->search({search_this => $driver,
   search_type => 'cost',
   solutions_to_find => 0,
   maximum_depth => 5,
   cost_cannot_increase => 1,
   initial_cost => $driver->distance_to_urbana,
  });
#print "md \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Chicago..Urbana
", 'ts2 nd max depth cost');


  $travel_search->search({search_this => $driver,
   search_type => 'cost',
   initial_cost => $driver->distance_to_urbana,
   solutions_to_find => 0,
   do_not_repeat_values => 1
  });
#print "dnr \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
",
'ts2 nd cost no repeat values');


  $driver->move('Duluth'); #start out in Duluth
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   search_type => 'cost',
   initial_cost => $driver->distance_to_urbana,
  });
  $full_path = '';
  if ($travel_search->solution_found) { #should be false, no path to Urbana
    $full_path = 'x';
#print "found path from Duluth to Urbana\n";
  }
  is ($full_path, 'x', 'ts2 nd from duluth cost');

  $driver->move('Minneapolis'); #start out in Minneapolis
  $travel_search->search({search_this => $driver,
   search_type => 'cost',
   maximum_depth => 8,
   no_value_function => 1,
   solutions_to_find => 0,
   initial_cost => $driver->distance_to_urbana,
  });
#print "md \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
#    print join("..", @{$travel_search->path})."\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", @{$path})."\n";
      $full_path .= join("..", @{$path})."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
St. Paul..Madison..Rockford..Madison..Chicago..Urbana
St. Paul..Madison..St. Paul..Madison..Chicago..Urbana
St. Paul..Minneapolis..St. Paul..Madison..Chicago..Urbana
Duluth..Chicago..Urbana
Duluth..Chicago..Minneapolis..St. Paul..Madison..Chicago..Urbana
St. Paul..Minneapolis..Duluth..Chicago..Urbana
St. Paul..Madison..Chicago..Minneapolis..Duluth..Chicago..Urbana
St. Paul..Madison..St. Paul..Minneapolis..Duluth..Chicago..Urbana
St. Paul..Minneapolis..St. Paul..Minneapolis..Duluth..Chicago..Urbana
Duluth..Chicago..Minneapolis..Duluth..Chicago..Urbana
", 'ts2 nd cost distance can increase, no value function');

