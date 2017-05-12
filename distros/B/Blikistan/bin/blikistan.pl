#!/usr/bin/perl

# Example CGI script to run Blikistan

use strict;
use warnings;
use CGI qw/header/;
use Socialtext::Resting::Getopt qw/get_rester/;              
use Blikistan;
                                                             
print header();
my $r = get_rester( 'rester-config' => "$FindBin::Bin/.blog-rester" ); 

my $blikistan = Blikistan->new( rester => $r );
print $blikistan->print_blog;
