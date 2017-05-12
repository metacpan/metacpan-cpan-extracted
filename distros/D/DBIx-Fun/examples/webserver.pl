#!/usr/bin/perl

use strict;
use warnings;
use CGI::Application::Server;
use EmpApp;

my $server = CGI::Application::Server->new( 8082 );
$server->document_root( './template' );
$server->entry_points({ '/app' => 'EmpApp' });
$server->run;

