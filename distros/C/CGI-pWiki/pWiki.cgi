#!/usr/bin/perl
use CGI::pWiki;
use strict;
use vars qw($pWiki);
$pWiki = new CGI::pWiki(
    'DB' => '/var/lib/pWiki',
#   'error' => 1
    ) unless defined $pWiki;
$pWiki->server();
0;
