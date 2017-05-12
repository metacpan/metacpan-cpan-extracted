#!/usr/bin/perl

package WebGuess;
use strict;
use Contize;

sub new {
  my $self = {};
  bless $self;
  $self = new Contize($self);
  return $self;
}

sub setNumber {
  my $self = shift;
  $self->{number} = int(rand(100)) + 1;
}

sub display {
  my ($self, $content) = @_;
  print $content;
  $self->suspend();
}

sub getNum {
  my $self = shift;
  $self->display(<<"END");
    <form method=POST">
      Enter Guess: <input name="num">
      <input type=submit value="Guess"> <input type=submit name="done" value="Done"><br>
    </form>
END
  return $::q->param('num');
}

sub run {
  my $self = shift;
  $self->setNumber();
  my $guess;
  my $tries = 0;
  print "Hi! I'm thinking of a number from 1 to 100... can you guess it?<br>\n";
  do {
    $tries++;
    $guess = $self->getNum();
    print "It is smaller than $guess.<br>\n" if($guess > $self->{number});
    print "It is bigger than $guess.<br>\n" if($guess < $self->{number});
  } until ($guess == $self->{number});
  print "You got it! My number was in fact $self->{number}.<br>\n";
  print "It took you $tries tries.<br>\n";
}

package Main;

use strict;
use CGI;
use CGI::Session;
use Data::Dumper;

# Set up the CGI session and print the header
$::q = new CGI();
my $session = new CGI::Session(undef, $::q, {Directory=>'/tmp'});
print $session->header();

# If there is a guess object in the session use it, otherwise create a new
# WebGuess object and Contize it.
my $g = $session->param('guess') || new WebGuess();

# Fix stuff -- most importantly the Data::Dumper version of the object doesn't
# get recreated correctly (I don't know why)... so to work around it I re-eval
# the thing. And we must reset the callstack and the callcount.
my $VAR1;
eval(Dumper($g));
$g = $VAR1;
$g->resume();

# Add the WebGuess object to the session
$session->param('guess', $g);

# Enter the main loop of the WebGuess object
until($::q->param('done')) {
  $g->run();
}

# We won't get here until that exits cleanly (never!)
print "Done.";


