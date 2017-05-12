#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/darren/perl_lib';

require CGI::Portable;
my $globals = CGI::Portable->new();

use Cwd;
$globals->file_path_root( cwd() );  # let us default to current working dir
$globals->file_path_delimiter( $^O=~/Mac/i ? ":" : $^O=~/Win/i ? "\\" : "/" );

my %CONFIG = ( filename => 'static.html' );

$globals->set_prefs( \%CONFIG );
$globals->call_component( 'DemoTextFile' );

require CGI::Portable::AdapterCGI;
my $io = CGI::Portable::AdapterCGI->new();
$io->send_user_output( $globals );

1;
