#!/usr/bin/perl -w
use strict;
use warnings;
use CGI;
use CGI::Auth::Basic;
my $cgi  = CGI->new;

my $auth = CGI::Auth::Basic->new(
                cgi_object => $cgi,
                file       => './password.txt',
            );
$auth->check_user;
my $logoff = $auth->logoff_link;

my $pok = print $cgi->header
              . "$logoff You can use this program. "
              . 'Now anything that this program does is accessible! :)';
