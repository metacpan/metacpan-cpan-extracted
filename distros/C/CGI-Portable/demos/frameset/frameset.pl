#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/darren/perl_lib';

require CGI::Portable;
my $globals = CGI::Portable->new();

require CGI::Portable::AdapterCGI;
my $io = CGI::Portable::AdapterCGI->new();
$io->fetch_user_input( $globals );

$globals->current_user_path_level( 1 );
$globals->call_component( 'DemoFrameSet' );

$io->send_user_output( $globals );

1;
