#!/usr/bin/env perl
use Acme::Brainfuck qw/verbose/;

while(1)
{
  print "Say something to Backwards Man and then press enter: ";
  +[->,----------]<
  print 'Backwards Man says, "';
  [+++++++++++.<]<
  print "\" to you too.\n";
  ~
}
