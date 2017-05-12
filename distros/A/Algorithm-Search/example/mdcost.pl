#!/usr/bin/perl
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
   maximum_depth => 8,
  });

  $full_path = '';
  foreach my $path ($travel_search->paths) {
    $full_path .= join("..", @{$path})."\n";
  }

print "full path should return:
St. Paul..Madison..Rockford..Bloomington..Champaign..Urbana
St. Paul..Madison..Rockford..Bloomington..Champaign..Chicago..Urbana
St. Paul..Madison..Chicago..Urbana
Duluth..Chicago..Urbana";

print "\n\nfull path is\n$full_path\n";
