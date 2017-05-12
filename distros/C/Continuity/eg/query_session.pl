#!/usr/bin/perl

use strict;
use lib '../lib';
use Continuity;

Continuity->new(
  query_session => 'sid',
  cookie_session => 0
)->loop;

sub main {
  my ($request) = @_;
  my $session_id = $request->session_id;
  $request->print(qq{
    <h2>Query Session Example</h2>
    Your session ID is: $session_id<br>
    <a href="?sid=$session_id">Click here to continue</a>
  });
  $request->next;
  $request->print(qq{
    <h2>Query Session Example</h2>
    Your session ID is: $session_id<br>
    As you can see, we are tracking the session using a query variable. It can also be passed through a form POST.
    <form method=post action="/">
      <input type=hidden name=sid value="$session_id">
      <input type=submit value="Click here to continue">
    </form>
  });
  $request->next;
  $request->print(qq{
    <h2>Query Session Example</h2>
    Your session ID is: $session_id<br>
    Magical, eh? Your session is over now. <a href="/">Click here to get a new one</a>.
  });
}

