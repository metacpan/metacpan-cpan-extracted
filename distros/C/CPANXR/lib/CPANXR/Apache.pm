# $Id: Apache.pm,v 1.12 2003/09/30 20:49:02 clajac Exp $

package CPANXR::Apache;

use CPANXR::Apache::Header;
use CPANXR::Apache::Footer;
use CPANXR::Apache::Distribution;
use CPANXR::Apache::File;
use CPANXR::Apache::Symbol;
use CPANXR::Apache::Search;
use CPANXR::Apache::ClassBrowser;
use CPANXR::Apache::Stats;
use CPANXR::Apache::Visualizer;

use Apache::Constants qw(:common);
use CGI;

use strict;

sub handler {
  my ($r) = @_;

  my $path = $r->uri();
  my $q = CGI->new();

  my ($event) = $path =~ /\/(\w+)$/;

  if($event eq 'visualize') {
    CPANXR::Apache::Visualizer->visualize($r, $q);
  } else {
    $r->send_http_header("text/html");

    # Send header
    CPANXR::Apache::Header->header($r);

    if ($event eq 'dists' || $event eq '') {
      CPANXR::Apache::Distribution->find($r, $q);
    } elsif ($event eq 'list') {
      CPANXR::Apache::Distribution->list($r, $q);
    } elsif ($event eq 'show') {
      CPANXR::Apache::File->show($r, $q);
    } elsif ($event eq 'graph') {
      CPANXR::Apache::Visualizer->graph($r, $q);
    } elsif ($event eq 'find') {
      CPANXR::Apache::Symbol->find($r, $q);
    } elsif ($event eq 'search') {
      CPANXR::Apache::Search->search($r, $q);
    } elsif ($event eq 'stats') {
      CPANXR::Apache::Stats->stats($r, $q);
    } elsif ($event eq 'classes') {
      CPANXR::Apache::ClassBrowser->browse($r, $q);
    }

    # Send footer
    CPANXR::Apache::Footer->footer($r);
  }
  
  return OK;
}

1;
