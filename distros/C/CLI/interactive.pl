#!/usr/bin/perl -w

use strict;
use blib;

use Term::ReadLine;
use CLI;

my $term = new Term::ReadLine 'CLI test';
my $features = $term->Features;
$term->ornaments('md,me,,') if ($$features{ornaments});

my $cli = new CLI;

my ($time, $vel, $year, $month, $name, $angle);

$cli->add(VAR, 'Time', \$time, FLOAT, 0.0, {min => 0.0});
$cli->add(VAR, 'Velocity', \$vel, FLOAT, 0.0);
$cli->add(VAR, 'Year', \$year, INTEGER, 1999);
$cli->add(VAR, 'Month', \$month, INTEGER, 1, {min=>1,
					      max=>12});
$cli->add(VAR, 'Name', \$name, STRING, 'Fred');
$cli->add(VAR, 'Angle', \$angle, DEGREE, 0.0);

my $distance = sub {
  printf("Distance in $time hours at $vel km/h %.1f km\n", $time*$vel);
};

my @months = ('January', 'Feburary', 'March', 'April', 'May', 'June',
	      'July', 'August', 'September', 'October', 'November',
	      'December');

my $month_string = sub {
  printf "Month is $months[$month-1]\n";
};

my $echo = sub {
  my $line = shift;
  if (defined $line) {
    print "Got $line\n";
  } else {
    print "Got nothing\n";
  }
};

my $test = 0;
$test = 1 if ($0 =~ /test.pl$/);

my $quit = 0;
$cli->add(COMMAND, 'Quit', sub {$quit=1});
$cli->add(COMMAND, 'Distance', $distance);
$cli->add(COMMAND, 'Mstring', $month_string);
$cli->add(COMMAND, 'Echo', $echo);

$cli->restore_config('test.config');

my $line;
while (! $quit) {
  if ($test) {
    $line = <DATA>;
    print "> $line";
    last if (! defined $line);
  } else {
    $line = $term->readline('> ');
    next if ! defined $line;
  }
  $cli->parse($line);
}

$cli->save_config('test.config');

__DATA__
angle
angle 10:00
angle
time 20
velocity 10
distance
quit
  
