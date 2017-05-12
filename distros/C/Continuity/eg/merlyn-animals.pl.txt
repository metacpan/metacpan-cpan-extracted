#!/usr/bin/perl -w
use strict;

# This is the original version written by Merlyn,
# http://www.perlmonks.org/?node_id=200391

## I originally wrote this for a column,
## but haven't gotten around to using it yet.
## just think of an animal, and invoke it.
## It's an example of a self-learning game.
## When you choose not to continue, it'll dump out
## the data structure of knowledge it has accumulated.

use Data::Dumper;

my $info = "dog";

{
  try($info);
  redo if (yes("play again?"));
}
print "Bye!\n";
print Dumper($info);

sub try {
  my $this = $_[0];
  if (ref $this) {
    return try($this->{yes($this->{Question}) ? 'Yes' : 'No' });
  }
  if (yes("Is it a $this")) {
    print "I got it!\n";
    return 1;
  };
  print "no!?  What was it then? ";
  chomp(my $new = <STDIN>);
  print "And a question that distinguishes a $this from a $new would be? ";
  chomp(my $question = <STDIN>);
  my $yes = yes("And for a $new, the answer would be...");
  $_[0] = {
           Question => $question,
           Yes => $yes ? $new : $this,
           No => $yes ? $this : $new,
          };
  return 0;
}

sub yes {
  print "@_ (yes/no)?";
  <STDIN> =~ /^y/i;
}

