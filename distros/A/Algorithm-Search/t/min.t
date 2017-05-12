#!/usr/bin/perl
#Copyright 2008 Arthur S Goldstein
#min cost search
use Test::More tests => 1;

  package traveller;
#only to Urbana

  our $solution_found;
  our $min_solution_cost;
  %roads = (
   'Minneapolis' => [['St. Paul',10], ['Duluth',80]],
   'St. Paul' => [['Minneapolis',10], ['Madison',100]],
   'Madison' => [['Rockford',50], ['St. Paul',100], ['Chicago',100]],
   'Rockford' => [['Bloomington',100], ['Madison',50]],
   'Bloomington' => [['Champaign',50]],
   'Champaign' => [['Urbana',5], ['Chicago',100]],
   'Chicago' => [['Minneapolis',300], ['Urbana',95]],
   'Urbana' => [],
   'Duluth' => [['Chicago',400]],
   );

  sub new {return bless {}}
  sub next_moves {my $self = shift;
#print STDERR "Position is ".$self->{position}."\n";
    return @{$roads{$self->{position}}}}
  sub move {
    my $self = shift;
    my $road_taken = shift;
    my $previous_cost = shift;
    my $new_position = $road_taken->[0];
    my $new_cost = $previous_cost + $road_taken->[1];
#print STDERR "current position ".$self->{position}." ";
#print STDERR "pc $previous_cost np is $new_position nc is $new_cost\n";
    if ($solution_found && ($new_cost >= $min_solution_cost)) {return undef}
    $self->{position} = $new_position;
    $self->{cost} = $new_cost;
    return $new_cost;
  }
  sub copy {my $self = shift;
    my $copy = $self->new;
    $copy->{position} = $self->{position};
    return $copy;
  }

  sub is_solution {my $self = shift;
     if ($self->{position} eq 'Urbana') {
       $solution_found = 1;
       $min_solution_cost = $self->{cost};
       return 1;
     }
     else {
       return 0;
     }
   }

  package main;
  use Algorithm::Search;
  my $driver = new traveller;
  my $travel_search = new Algorithm::Search();

  $driver->move(['Minneapolis',0],0); #start out in Minneapolis
  $travel_search->search({search_this => $driver,
   max_steps => 1000,
   search_type => 'cost',
   solutions_to_find => 0,
   initial_cost => 0,
  });
  my $full_path = '';
  if ($travel_search->solution_found) { #should be true, path to Urbana
    my @paths = $travel_search->paths;
    my $latest_path = $paths[-1];
    foreach my $step (@$latest_path) {
      $full_path .= " ".$step->[0]." ";
#min cost path is the last solution found
    }
  }
  is ($full_path, " St. Paul  Madison  Chicago  Urbana ", "min cost");

