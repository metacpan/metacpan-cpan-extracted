#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein

#demonstrates 'dfs' type search

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
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
      $full_path .= join("..", @{$path})."\n";
    }
  }
  print "Full path should be
St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
";
  print "full path is \n$full_path\n\n";

