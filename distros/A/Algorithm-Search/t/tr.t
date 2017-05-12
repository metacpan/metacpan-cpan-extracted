#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein

use Test::More tests => 6;

  package r_traveller;

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
  sub move_after_given {
    my $self = shift;
    my $previous = shift;
    my $move_count = 0;
    if ($previous) {
      $move_count = $previous->[2] + 1;
    }
    my $city = $self->{position};
#print STDERR "mag city $city previous ".join("..",@$previous)."\n";
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
     return $self->{position} eq $destination;}
  sub set_destination {my $self = shift; $destination = shift;}

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
  $r_driver->set_destination('Urbana');
  $travel_search->search({
   search_this => $r_driver,
   search_type => 'rdfs',
   max_steps => 90,
   solutions_to_find => 0,
  });
  my $full_path;
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
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
", 'first search');


  $r_driver->move([undef, 'Minneapolis']); #start out in Minneapolis
  $r_driver->set_destination('Urbana');
  $travel_search->search({
   search_this => $r_driver,
   search_type => 'rdfs',
   solutions_to_find => 2
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
  $r_driver->set_destination('Urbana');
  $travel_search->search({
   maximum_depth => 4,
   search_this => $r_driver,
   search_type => 'rdfs',
   solutions_to_find => 0,
   return_search_trace => 1,
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
", 'max depth');

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
            'cost' => 0,
            'move' => [
                        'Minneapolis',
                        'St. Paul',
                        0
                      ],
            'value_before' => 'Minneapolis',
            'value_after' => 'St. Paul'
          },
          {
            'commit' => undef,
            'cost' => 0,
            'move' => [
                        'St. Paul',
                        'Madison',
                        1
                      ],
            'value_before' => 'St. Paul',
            'value_after' => 'Madison'
          },
          {
            'commit' => undef,
            'cost' => 0,
            'move' => [
                        'Madison',
                        'Rockford',
                        0
                      ],
            'value_before' => 'Madison',
            'value_after' => 'Rockford'
          },
          {
            'commit' => undef,
            'cost' => 0,
            'move' => [
                        'Rockford',
                        'Bloomington',
                        0
                      ],
            'value_before' => 'Rockford',
            'value_after' => 'Bloomington'
          },
          {
            'commit' => undef,
            'cost' => 0,
            'move' => [
                        'Madison',
                        'Chicago',
                        2
                      ],
            'value_before' => 'Madison',
            'value_after' => 'Chicago'
          },
          {
            'commit' => undef,
            'cost' => 0,
            'move' => [
                        'Chicago',
                        'Urbana',
                        1
                      ],
            'value_before' => 'Chicago',
            'value_after' => 'Urbana'
          },
          {
            'commit' => undef,
            'cost' => 0,
            'move' => [
                        'Minneapolis',
                        'Duluth',
                        1
                      ],
            'value_before' => 'Minneapolis',
            'value_after' => 'Duluth'
          }
        ],
   'rdfs max depth search trace');

  $r_driver->move([undef, 'Duluth']); #start out in Minneapolis
  $r_driver->set_destination('Urbana');
  $travel_search->search({
   search_this => $r_driver,
   search_type => 'rdfs',
   solutions_to_find => 0,
  });
  $full_path = '';
  if ($travel_search->solution_found) { #should be false, no path to Urbana
    $full_path = 'x';
#print "found path from Duluth to Urbana\n";
  }
  is ($full_path, '', 'from duluth');

  $r_driver->move([undef, 'Minneapolis']); #start out in Minneapolis
  $r_driver->set_destination('Dallas');
  $travel_search->search({
   search_this => $r_driver,
   search_type => 'rdfs',
   solutions_to_find => 0,
  });
  $full_path = '';
  if ($travel_search->solution_found) { #should be false, path to Dallas
    $full_path = 'x';
#print "found path from Minneapolis to Dallas\n";
  }
  is ($full_path, '', 'to dallas');

#print "sc3\n";

