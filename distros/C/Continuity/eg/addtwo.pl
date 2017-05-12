#!/usr/bin/perl

use strict;
use lib '../lib';
use Continuity;

Continuity->new->loop;

sub main {
  my $request = shift;

  $request->print(qq{
    <form>
      Enter first number:
      <input type=text name=num><input type=submit>
    </form>
  });
  $request->next;
  my $num1 = $request->param('num');

  $request->print(qq{
    <form>
      Enter second number:
      <input type=text name=num><input type=submit>
    </form>
  });
  my $num2 = $request->next->param('num');

  my $sum = $num1 + $num2;
  $request->print(qq{
    <h2>The sum of $num1 and $num2 is $sum!</h2>
  });
}

