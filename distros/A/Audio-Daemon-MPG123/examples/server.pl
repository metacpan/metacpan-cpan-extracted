#!/usr/local/bin/perl

use Audio::Daemon::MPG123::Server;

sub log {
  my $type = shift;
  my $msg = shift;
  my ($line, $function) = (@_)[2,3];
  $function = (split '::', $function)[-1];
  printf("%6s:%12s %7s:%s\n", $type, $function, '['.$line.']', $msg);
}

my $daemon = new Audio::Daemon::MPG123::Server( Port => 9101, Log => \&log, Allow => '10.10.10.0/24, 127.0.0.1' );

$daemon->mainloop;
