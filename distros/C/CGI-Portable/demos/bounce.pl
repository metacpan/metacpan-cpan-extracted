#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/darren/perl_lib';

require CGI::Portable;
my $globals = CGI::Portable->new();

require CGI::Portable::AdapterCGI;
my $io = CGI::Portable::AdapterCGI->new();
$io->fetch_user_input( $globals );

my %CONFIG = ();

$globals->set_prefs( \%CONFIG );
$globals->call_component( 'DemoRedirect' );

$io->send_user_output( $globals );

1;
