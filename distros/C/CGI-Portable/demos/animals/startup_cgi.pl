#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/darren/perl_lib';

require CGI::Portable;
my $globals = CGI::Portable->new();

use Cwd;
$globals->file_path_root( cwd() );  # let us default to current working directory
$globals->file_path_delimiter( $^O=~/Mac/i ? ":" : $^O=~/Win/i ? "\\" : "/" );

$globals->set_prefs( 'config.pl' );
$globals->current_user_path_level( 1 );

require CGI::Portable::AdapterCGI;
my $io = CGI::Portable::AdapterCGI->new();

$io->fetch_user_input( $globals );
$globals->call_component( 'DemoAardvark' );
$io->send_user_output( $globals );

1;
