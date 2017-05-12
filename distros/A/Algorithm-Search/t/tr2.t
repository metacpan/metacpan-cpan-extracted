#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein

use Test::More tests => 9;
my $loaded = 1;

  package r_traveller;
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

  sub new {return bless {}}
  sub move_after_given {
    my $self = shift;
    my $previous = shift;
    my $move_count = 0;
    if ($previous) {
      $move_count = $previous->[2] + 1;
#print STDERR "previous ".join("..",@$previous)."\n";
    }
    my $city = $self->{position};
#print STDERR "mag city $city\n";
    if (scalar(@{$roads{$city}}) > $move_count) {
      return [$self->{position}, $roads{$city}->[$move_count], $move_count]
    }
    else {
      return undef;
    }
  }
  sub reverse_move {my ($self, $move) = @_; $self->{position} = $move->[0];}
  sub move {my ($self, $move) = @_; $self->{position} = $move->[1];
    return $distance_to_urbana{$self->{position}};
  }
  sub value {my $self = shift; return $self->{position}}
  sub distance_to_final_state {my $self = shift;
     return $distance_to_urbana{$self->{position}};}
  sub is_solution {
    my $self = shift;
    return $self->{position} eq 'Urbana';
  }

  package main;
  use Algorithm::Search;
  my $r_driver = new r_traveller;
  $travel_search = new Algorithm::Search();

  sub travel_path {
    my $path = shift;
    my @path_out;
    foreach my $move (@$path) {
      push @path_out, $move->[1];
    }
    return @path_out;
  }

  $r_driver->move([undef, 'Minneapolis']); #start out in Minneapolis
  $travel_search->search({
   search_this => $r_driver,
   search_type => 'rdfs',
   solutions_to_find => 0,
  });
  my $full_path;
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", travel_path($path))."\n";
      $full_path .= join("..", travel_path($path))."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
Duluth..Chicago..Urbana
", 'rdfs first search');

  $r_driver->move([undef, 'Minneapolis']); #start out in Minneapolis
  $travel_search->search({
   search_this => $r_driver,
   search_type => 'rdfs',
   solutions_to_find => 2,
  });
#print "sf \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", travel_path($path))."\n";
      $full_path .= join("..", travel_path($path))."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
", 'find 2');

  $r_driver->move([undef, 'Minneapolis']); #start out in Minneapolis
  $travel_search->search({
   maximum_depth => 4,
   search_this => $r_driver,
   search_type => 'rdfs',
   solutions_to_find => 0,
  });
#print "md \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", travel_path($path))."\n";
      $full_path .= join("..", travel_path($path))."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Chicago..Urbana
Duluth..Chicago..Urbana
", 'rdfs max depth');


  $r_driver->move([undef, 'Duluth']); #start out in Duluth
  $travel_search->search({
   search_this => $r_driver,
   search_type => 'rdfs',
   solutions_to_find => 0,
  });
  $full_path = '';
  if ($travel_search->solution_found) {
    $full_path = 'x';
  }
  is ($full_path, 'x', 'from duluth');

  $r_driver->move([undef, 'Minneapolis']); #start out in Minneapolis
  $travel_search->search({
   search_this => $r_driver,
   search_type => 'rdfs',
   do_not_repeat_values => 1,
   solutions_to_find => 0,
  });
#print "md \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", travel_path($path))."\n";
      $full_path .= join("..", travel_path($path))."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
", 'rdfs max dci dnrv');

#print STDERR "xx md \n";
  $r_driver->move([undef, 'Minneapolis']); #start out in Minneapolis
  $travel_search->search({
   search_this => $r_driver,
   search_type => 'rdfs',
   initial_cost => $r_driver->distance_to_final_state,
   cost_cannot_increase => 1,
   solutions_to_find => 2,
  });
#print STDERR "md \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print STDERR "found path from Minneapolis to Urbana\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", travel_path($path))."\n";
      $full_path .= join("..", travel_path($path))."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Chicago..Urbana
", 'not distance increas sol 2');


  $r_driver->move([undef, 'Minneapolis']); #start out in Minneapolis
  $travel_search->search({
   search_this => $r_driver,
   search_type => 'rdfs',
   solutions_to_find => 0,
   initial_cost => $r_driver->distance_to_final_state,
   cost_cannot_increase => 1,
   maximum_depth => 5,
  });
#print "md \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", travel_path($path))."\n";
      $full_path .= join("..", travel_path($path))."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Chicago..Urbana
", 'rdfs max depth 5 all sol not inc dist');

  $r_driver->move([undef, 'Minneapolis']); #start out in Minneapolis
  $travel_search->search({
   search_this => $r_driver,
   search_type => 'rdfs',
   solutions_to_find => 0,
   do_not_repeat_values => 1,
  });
#print "md \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", travel_path($path))."\n";
      $full_path .= join("..", travel_path($path))."\n";
    }
  }
  is ($full_path,
"St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
", 'rdfs dnotrepeatvalues ');

  $r_driver->move([undef, 'Minneapolis']); #start out in Minneapolis
  $travel_search->search({
   search_this => $r_driver,
   search_type => 'rdfs',
   solutions_to_find => 0,
   no_value_function => 1,
   maximum_depth => 7,
  });
#print "md \n";
  $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
#print "found path from Minneapolis to Urbana\n";
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
#      print "Path ".$path_count++." ";
#      print join("..", travel_path($path))."\n";
      $full_path .= join("..", travel_path($path))."\n";
    }
  }
  is ($full_path,
"St. Paul..Minneapolis..St. Paul..Minneapolis..Duluth..Chicago..Urbana
St. Paul..Minneapolis..St. Paul..Madison..Chicago..Urbana
St. Paul..Minneapolis..Duluth..Chicago..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
St. Paul..Madison..Rockford..Madison..Chicago..Urbana
St. Paul..Madison..St. Paul..Minneapolis..Duluth..Chicago..Urbana
St. Paul..Madison..St. Paul..Madison..Chicago..Urbana
St. Paul..Madison..Chicago..Minneapolis..Duluth..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
Duluth..Chicago..Minneapolis..St. Paul..Madison..Chicago..Urbana
Duluth..Chicago..Minneapolis..Duluth..Chicago..Urbana
Duluth..Chicago..Urbana
", 'rdfs max d 7 no value fun dis can increase all sol ');

