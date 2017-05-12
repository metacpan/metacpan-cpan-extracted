#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein

#demonstrates reversible depth first search

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
    my $path_count = 0;
    foreach my $path ($travel_search->paths) {
      $full_path .= join("..", travel_path($path))."\n";
    }
  }
  print "full path should be \n
St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
Duluth..Chicago..Urbana
";
  print "\nfull path is \n$full_path\n\n";

