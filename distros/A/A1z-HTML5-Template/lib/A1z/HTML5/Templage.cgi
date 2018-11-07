#!/usr/bin/env perl

use 5.10.0;     
use strict;     
use warnings; 


# DO CHANGE 

# Linux: Path to Perl libraries (local) if running on a shared hosting 
use lib qw(/home/dt/perl5/lib/perl5);

# Linux: Path to folder containing text files
use lib qw(/home/dt/2CPAN/A1z-HTML5-Template/); 

# Windows: Path to folder containing Template.pm
use lib qw(C:/Users/hp/up/A1z/Html5); 

# Paths based on Operating System this app is running on
my %os;
%os = 
(
	win => 
	{
		base => "C:/Users/hp/up/A1z/Html5",
		cgibase => "C:/Users/hp/up/A1z/Examples/Ex_Html5",
	},
		
	linux =>
	{
		base => "/home/bislinks/cgi-bin/A1z/Html5",
		cgibase => "/home/bislinks/cgi-bin/A1z/Examples/Ex_Html5",
	},		
);

# END USER CONFIG




# DO NOT CHANGE 

my %sys;
if ($ENV{OS} and $ENV{OS} =~ /^Win/i )
{
	$sys{base} = "$os{win}->{base}" || '.';
	$sys{cgibase} = "$os{win}->{cgibase}";
}
elsif (!defined $ENV{OS} or $ENV{OS} eq '' )
{
	$sys{base} = "$os{linux}->{base}";
	$sys{cgibase} = "$os{linux}->{cgibase}";
}
else
{
	$sys{base} = "$os{linux}->{base}";
	$sys{cgibase} = "$os{linux}->{cgibase}";

}


use A1z::HTML5::Template;	 

my $package_name = 'HTML5::Template'; 

# HTML stuff 

my $h = Template->new(); 


# HTML5 output from Template.pm

say $h->header('utf8'); 	# 
say $h->start_html(); 
say $h->head_title("$package_name"); 
say $h->head_meta(); 
say $h->head_meta("description---How to use $package_name", 
"keywords---Package, perl module, html5, cgi compatible", 
"author---webmaster at bislinks.com",
); 
say $h->head_js_css(); 
say $h->head_js_css('/A1z/Html5/Template.css'); 
say $h->end_head(); 
say $h->begin_body();
say $h->body_topnavbar( file => "/js/utils/top-nav-bar.js", name => "More" );


say qq{<h1>$package_name</h1>
<div id="main-content" class="container">
}; 


# output file as accordion
say $h->body_accordion( $h->open_file("$sys{cgibase}/open_file_example.txt", 'menu', 'Menu') ); 

# as table 
say $h->body_accordion( $h->open_file("$sys{cgibase}/open_file_example.txt", 'table', 'Items in \'Table\' are filtered by one hash #') ); 

# as accordion 
say $h->body_accordion( $h->open_file("$sys{cgibase}/open_file_example.txt", 'accordion', 'Items in \'accordion\' are filtered by two dashes --') ); 

# as tabs 
say $h->body_accordion( $h->open_file("$sys{cgibase}/open_file_example.txt", 'tabs', 'Items in \'tabs\' are filtered by two equal signs ==') ); 

# as dialog 
say $h->body_accordion( $h->open_file("$sys{cgibase}/open_file_example.txt", 'dialog', 'Opens a dialog box on click of a button/link') ); 

# math works 
say $h->body_article( header => "Mathematics", content => $h->math1("", "") );

# math works 
say $h->body_article( header => "Times Table", content => $h->timestable("2") );

say qq{</div>
<!--end main-->
};


say $h->body_js_css(); 
say $h->end_body();
say $h->end_html(); 


__DATA__ 
Where am I				in DATA section of .pl 
Why is this showing up?		This shows up when the given file path is wrong or for some reason unable to open it!

