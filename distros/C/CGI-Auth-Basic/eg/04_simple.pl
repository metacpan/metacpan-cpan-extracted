#!/usr/bin/perl -w
use strict;
use warnings;
use CGI::Auth::Basic;

CGI::Auth::Basic->new(
    cgi_object => 'AUTOLOAD_CGI',
    file       => './password.txt',
)->check_user;

my $pok = print "Content-type: text/html\n\n"
              . 'You can use this program. '
              . 'Now anything that this program does is accessible! :)'
              ;
