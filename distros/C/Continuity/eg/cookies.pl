#!/usr/bin/perl

use strict;
use lib '../lib';
use Continuity;

Continuity->new->loop;

sub main {
  my $r = shift;
  $r->set_cookie( CGI->cookie( -name => 'continuity-cookie-demo', -value => 10));
  $r->print("Setting 'continuity-cookie-demo' to 10");
  $r->next;
  my $val1 = $r->get_cookie('continuity-cookie-demo');
  $r->print("Got 'continuity-cookie-demo' == $val1");
  $r->next;
  my $val2 = $r->get_cookie('continuity-cookie-demo');
  $r->set_cookie( CGI->cookie( -name => 'continuity-cookie-demo', -value => 20));
  $r->print("... still got 'continuity-cookie-demo' == $val2");
  $r->print("Setting 'continuity-cookie-demo' to 20");
  $r->next;
  my $val3 = $r->get_cookie('continuity-cookie-demo');
  $r->print("Got 'continuity-cookie-demo' == $val3");
  $r->print("All done with cookie demo!");
}

