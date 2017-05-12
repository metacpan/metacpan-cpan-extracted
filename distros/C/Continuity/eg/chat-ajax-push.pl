#!/usr/bin/perl

# "HTTP Push" is not readily attainable, so instead we will simulate it using a
# long-pull, aka "Comet". The client browser simply opens an HTTP connection to
# the server and waits for a response. The server doesn't respond until there
# is some event (here a new message), giving the appearance of HTTP-push.
#
# Each user gets three continuations for these three cases:
#
#   - Initial load or reload of the page
#   - Sending a message (uses AJAX on the client)
#   - Recieving messages (uses COMET on the client)

use strict;
use lib '../lib';
use Continuity;
use Coro::Event;

my @messages;    # Global (shared) list of messages
my $got_message; # Flag to indicate that there is a new message to display

my $server = Continuity->new(
  port => 5000,
  path_session => 1,
  cookie_session => 'sid',
  debug_level => 3,
);

$server->loop;

# This is the main entrypoint. We are looking for one of three things -- a
# pushstream, a sent message, or a request for the main HTML. We delegate each
# of these cases, none of which will return (they all loop forever).
sub main {
  my ($req) = @_;
  
  #my $path = $req->request->url->path;
  my $path = $req->request->url_path;
  print STDERR "Path: '$path'\n";

  # If this is a request for the pushtream, then give them that
  if($path =~ /pushstream/) {
    pushstream($req);
  }
  
  # If they are sending us a message, we give them a thread for that too
  if($path =~ /sendmessage/) {
    send_message($req);
  }

  # Otherwise, lets give them the base page
  send_base_page($req);
}

# Here we accept a connection to the browser, and keep it open. Meanwhile we
# watch the global $got_message variable, and when it gets touched we send off
# the list of messages through the held-open connection. Then we let the
# browser open a new connection and begin again.
sub pushstream {
  my ($req) = @_;
  # Set up watch event -- this will be triggered when $got_message is written
  my $w = Coro::Event->var(var => \$got_message, poll => 'w');
  while(1) {
    print STDERR "**** GOT MESSAGE, SENDING ****\n";
    my $log = join "<br>", @messages;
    $req->print($log);
    $req->next;
    print STDERR "**** Waiting for got_message indicator ****\n";
    $w->next;
  }
}


# Watch for the user to send us a message. As soon as we get it, we add it to
# our list of messages and touch the $got_message flag to let all the
# pushstreams know.
sub send_message {
  my ($req) = @_;
  while(1) {
    my $msg = $req->param('message');
    my $name = $req->param('username');
    if($msg) {
      unshift @messages, "$name: $msg";
      pop @messages if $#messages > 15; # Only keep the recent 15 messages
    }
    $got_message = 1;
    $req->print("Got it! ($msg)");
    $req->next;
  }
}

# This isn't a pushstream, nor a new message. It is just the main page. We loop
# in case they ask for it multiple times :)
sub send_base_page {
  my ($req) = @_;
  while(1) {
    $req->print(qq{
      <html>
        <head>
          <title>Chat!</title>
          <script src="/jquery.js" type="text/javascript"></script>
          <script src="/chat-ajax-push.js" type="text/javascript"></script>
        </head>
        <body>
          <form id=f>
          <input type=text id=username name=usernamename size=10>
          <input type=text id=message name=message size=50>
          <input type=submit name="sendbutton" value="Send" id="sendbutton">
          <span id=status></span>
          </form>
          <br>
          <div id=log>-- no messages yet --</div>
        </body>
      </html>
    });
    $req->next;
  }
}


