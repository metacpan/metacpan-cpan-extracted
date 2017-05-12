#!/usr/bin/perl

use strict;
use lib '../lib';
use Continuity;

my @messages; # Shared by all sessions

my $server = Continuity->new(
  port => 16000,
  path_session => 1,
);

$server->loop;

sub main {
  my ($req) = @_;

  my $username;

  while(1) {

    my $messages_html = join '', map { $_ . '<br>' } @messages;

    $req->print(qq{
      <html>
        <head>
          <title>Chat!</title>
        </head>
        <body>
          <form id=f>
            <input type=text id=username name=username size=10 value="$username">
            <input type=text id=message name=message size=50>
            <input type=submit name="sendbutton" value="Send" id="sendbutton">
          </form>
          <br>
          <div id=log>$messages_html</div>
        </body>
      </html>
    });

    $req->next; # Get their response to that

    $username = $req->param('username');
    my $msg = $req->param('message');
    if($msg) {
      unshift @messages, "$username: $msg";
      pop @messages if $#messages > 30;
    }
  }
}

