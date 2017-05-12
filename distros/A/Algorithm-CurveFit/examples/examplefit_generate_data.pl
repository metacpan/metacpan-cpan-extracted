#!/usr/bin/perl
  my @xdata; 
  my @ydata;
  my $func = sub {-3*cos($_/10) + 10*sin($_/10)};
  foreach (-100..100) {
	  print $_*(0.75+rand(0.5)), ' ', $func->($_*(0.6+rand(0.8))), "\n";
	  warn("$_ ".$func->($_)."\n");
  }

