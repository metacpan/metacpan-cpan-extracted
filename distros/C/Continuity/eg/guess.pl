#!/usr/bin/perl

use lib '../lib';
use strict;
use warnings;
use Continuity;

sub getNum {
  my $request = shift;
  $request->print( qq{
    Enter Guess: <input name="num" id=num>
    <script>document.getElementById('num').focus()</script>
    </form>
  });
  $request = $request->next;
  my $num = $request->param('num');
  return $num;
}

sub main {
  my $request = shift;
  my $guess;
  my $number = int(rand(100)) + 1;
  my $tries = 0;
  my $out = qq{
    <form method=POST>
      Hi! I'm thinking of a number from 1 to 100... can you guess it?<br>
  };
  do {
    $request->print($out);
    $guess = getNum($request);
    if($guess) {
      $tries++;
      $out .= "It is smaller than $guess.<br>\n" if $guess > $number;
      $out .= "It is bigger than $guess.<br>\n" if $guess < $number;
    }
  } until ($guess == $number);
  $request->print("You got it! My number was in fact $number.<br>\n");
  $request->print("It took you $tries tries.<br>\n");
}

my $server = Continuity->new(
  port => 8080,
);

return $server->loop;

