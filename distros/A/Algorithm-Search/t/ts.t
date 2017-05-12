#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein
use Test::More tests => 14;

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
", 'minneapolis to urbana paths');

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
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
", 'limit 2');


  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
   return_search_trace => 1,
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
"St. Paul..Madison..Chicago..Urbana
", 'max depth dfs');

#use Data::Dumper;
#print STDERR "x: ".Dumper($travel_search->search_trace)."\n";
  is_deeply($travel_search->search_trace,
   [
          {
            'commit' => undef,
            'cost' => undef,
            'move' => undef,
            'value_before' => undef,
            'value_after' => 'Minneapolis'
          },
          {
            'commit' => undef,
            'cost' => undef,
            'move' => 'Duluth',
            'value_before' => 'Minneapolis',
            'value_after' => 'Duluth'
          },
          {
            'commit' => undef,
            'cost' => undef,
            'move' => 'St. Paul',
            'value_before' => 'Minneapolis',
            'value_after' => 'St. Paul'
          },
          {
            'commit' => undef,
            'cost' => 0,
            'move' => 'Madison',
            'value_before' => 'St. Paul',
            'value_after' => 'Madison'
          },
          {
            'commit' => undef,
            'cost' => 0,
            'move' => 'Rockford',
            'value_before' => 'Madison',
            'value_after' => 'Rockford'
          },
          {
            'commit' => undef,
            'cost' => 0,
            'move' => 'Bloomington',
            'value_before' => 'Rockford',
            'value_after' => 'Bloomington'
          },
          {
            'commit' => undef,
            'cost' => 0,
            'move' => 'Chicago',
            'value_before' => 'Madison',
            'value_after' => 'Chicago'
          },
          {
            'commit' => undef,
            'cost' => 0,
            'move' => 'Urbana',
            'value_before' => 'Chicago',
            'value_after' => 'Urbana'
          }
        ],
  'dfs max depth trace');


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
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
", 'dfs no repeat values');


  $driver->move('Duluth'); #start out in Duluth
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
  });
  $full_path = '';
  if ($travel_search->solution_found) { #should be false, no path to Urbana
    $full_path = 'x';
#print "found path from Duluth to Urbana\n";
  }
  is ($full_path, '', 'from duluth dfs');

  $driver->move('Minneapolis'); #start out in Minneapolis
  $driver->set_destination('Dallas');
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
  });
  $full_path = '';
  if ($travel_search->solution_found) { #should be false, path to Dallas
    $full_path = 'x';
#print "found path from Minneapolis to Dallas\n";
  }
  is($full_path, '', 'to dallas dfs');

#print "sc3\n";

  $driver->move('Minneapolis'); #start out in Minneapolis
  $driver->set_destination('Urbana');
  $travel_search->search({search_this => $driver,
    search_type => 'bfs',
   solutions_to_find => 0,
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
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
", 'bfs');

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
"St. Paul..Madison..Chicago..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
", 'bfs find 2');


  $travel_search->search({search_this => $driver,
    search_type => 'bfs',
   solutions_to_find => 0,
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
", 'bfs max depth');

#use Data::Dumper;
#print STDERR "y: ".Dumper($travel_search->search_trace)."\n";
 is_deeply($travel_search->search_trace,
  [
          {
            'commit' => undef,
            'cost' => undef,
            'move' => undef,
            'value_before' => undef,
            'value_after' => 'Minneapolis'
          },
          {
            'commit' => undef,
            'cost' => undef,
            'move' => 'Duluth',
            'value_before' => 'Minneapolis',
            'value_after' => 'Duluth'
          },
          {
            'commit' => undef,
            'cost' => undef,
            'move' => 'St. Paul',
            'value_before' => 'Minneapolis',
            'value_after' => 'St. Paul'
          },
          {
            'commit' => undef,
            'cost' => 0,
            'move' => 'Madison',
            'value_before' => 'St. Paul',
            'value_after' => 'Madison'
          },
          {
            'commit' => undef,
            'cost' => 0,
            'move' => 'Rockford',
            'value_before' => 'Madison',
            'value_after' => 'Rockford'
          },
          {
            'commit' => undef,
            'cost' => 0,
            'move' => 'Chicago',
            'value_before' => 'Madison',
            'value_after' => 'Chicago'
          },
          {
            'commit' => undef,
            'cost' => 0,
            'move' => 'Bloomington',
            'value_before' => 'Rockford',
            'value_after' => 'Bloomington'
          },
          {
            'commit' => undef,
            'cost' => 0,
            'move' => 'Urbana',
            'value_before' => 'Chicago',
            'value_after' => 'Urbana'
          }
        ],
  'bfs max depth search trace');

  $travel_search->search({search_this => $driver,
    search_type => 'bfs',
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
"St. Paul..Madison..Chicago..Urbana
", 'bfs not repeat values');


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
  is ($full_path, '', 'bfs duluth');

  $driver->move('Minneapolis'); #start out in Minneapolis
  $driver->set_destination('Dallas');
  $travel_search->search({search_this => $driver,
   solutions_to_find => 0,
    search_type => 'bfs',
  });
  $full_path = '';
  if ($travel_search->solution_found) { #should be false, path to Dallas
    $full_path = 'x';
#print STDERR "found path from Minneapolis to Dallas\n";
  }
  is ($full_path, '', 'bfs to dallas');

#print "sc6\n";

