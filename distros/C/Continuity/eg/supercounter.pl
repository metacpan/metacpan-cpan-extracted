#!/usr/bin/perl

use lib '../lib';
use strict;
use warnings;
use URI::Escape;

=head1 Summary

This is pretty clearly an emulation of the Seaside tutorial.
Except the overhead for seaside is a bit bigger than this...
I'd say. There is no smoke or mirrors here, just the raw
code. We even implement our own 'prompt'...

=cut

use Continuity;
my $server = new Continuity(
    port => 8080,
    query_session => 'sid',
);


sub stats {
  my ($request) = @_;
  my $session_id = $request->session_id;
  my $mapper = $server->{mapper};
  my $sessions = $mapper->{sessions};
  my $session_count = scalar keys %$sessions;
  $request->print("SID: $session_id<br>Server: $server<br>Mapper: $mapper<br>$sessions<br><pre>Sessions:\n");
  use Data::Dumper;
  $request->print(Dumper($sessions));
  $request->print("Session count: $session_count<br>");
}


package Counter;

my $counter_num = 0;

sub new {
  my ($class) = shift;
  my $self = { count => 0, instance => $counter_num++ };
  bless $self, $class;
  return $self;
}

# Ask a question and keep asking until they answer. General purpose prompt.
sub prompt {
  my ($self, $request, $msg, @ops) = @_;
  $request->print("$msg<br>");
  foreach my $option (@ops) {
    my $uri_option = uri_escape($option);
    $request->print(qq{<a href="?option=$uri_option">$option</a><br>});
  }
  stats($request);
  my $option = $request->next->param('option');
  print STDERR "*** Got option: $option\n";
  return $option || prompt($request, $msg, @ops);
}

sub main {
  my ($self, $request) = @_;
  while(1) {

  if($self->{count}) {
    $request->print("<h1>The Answer to Life, The Universe, and Everything</h1>");
  }

  # When we are first called we get a chance to initialize stuff
  my $count = 0;
  $request->next;

  # After we're done with that we enter a loop. Forever.
  while(1) {
    if($count == 42) {
      $request->print("<h1>The Answer to Life, The Universe, and Everything</h1>");
    }
    my $action = prompt($request, "Count: $count", '++','--');
    my $add = {'++' => 1, '--' => -1}->{$action};
    if($count >= 0 && $count + $add < 0) {
      my $choice = prompt($request, "Do you really want to GO NEGATIVE?", "Yes", "No");
      print STDERR "... again, they chose $choice\n";
      $add = 0 if $choice eq 'No';
    }
    $count += $add;
  }

  }
}


package Main;


sub main {
  my $request = shift;

  my @counter = map { new Counter } 1..5;

  while(1) {
    foreach my $counter (@counter) {
      $counter->render;
    }
    $request->next;
    foreach my $counter (@counter) {
      $counter->process_input($request);
    }
  }
}

$server->loop;
