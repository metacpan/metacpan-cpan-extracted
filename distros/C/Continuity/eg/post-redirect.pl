#!/usr/bin/perl

# The idea here is to find a way to deal with the back button well. We will
# send a 302 status between each page. Then we can process their data and give
# them a new ID. When they hit 'back', it doesn't re-processes their data.
#
# Alternatively, maybe the 302 can be used as not just a back-button indicator,
# but as an on-purpose 'block' to keep them from backing out of the site (going
# back past a transaction, for example). The back button would still thus work,
# but only _within_ the site, and we'd have server-side programatic control
# over what happens when people use it.
#
# Or something like that.

use strict;
use lib '../lib';
use Continuity;

Continuity->new(port => 8081)->loop;

sub main {
  my ($request) = @_;
  my $pageID;
  my $num = 0;
  my $msg = '';
  my %cache;
  my $count = 0;
  my %num_memory;
  while(1) {
    my $next_pageID = sprintf "%x", int rand 0xffffffff;
    print STDERR "Displaying form. NextPID: $next_pageID\n";
    $request->print(qq{
      <html>
        <body>
          <h1>$msg</h1>
          <h2>You chose: $num ($pageID)</h2>
          <form method=POST action="/">
            <input type=hidden name="pageID" value="$next_pageID">
            Number: <input type=text name=num><br>
            <input type=submit name=submit value="Send">
          </form>
        </body>
      </html>
    });
    $msg = '';
    $request->next;
    $pageID = $request->param('pageID');
    if($cache{$pageID}) {
      print STDERR "Already been here...\n";
      if($cache{$pageID} == $count - 1) {
        $msg = "RELOAD detected ($cache{$pageID})!";
      } else {
        $msg = "BACK detected ($cache{$pageID})!";
      }
      $num = $num_memory{$cache{$pageID}}; # Lets just get the num from before
    } else {
      $cache{$pageID} = $count++;
      $num = $request->param('num');
      $num_memory{$cache{$pageID}} = $num;
    }
    print STDERR "Num: $num\tPageID: $pageID\n";
    print STDERR "Doing redirect after POST\n";
    $request->request->conn->send_redirect("/?pageID=$pageID",303);
    $request->next;
  }
}

