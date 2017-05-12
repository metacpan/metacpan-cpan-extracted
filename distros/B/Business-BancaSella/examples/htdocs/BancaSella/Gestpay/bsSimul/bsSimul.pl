#!/usr/bin/perl

use CGI qw/:standard/;

my $CGI = new CGI;

my $shopping 	= param('a');
my $b		= param('b');

print header, start_html,h1('Simulated page of Banca Sella');
print <<HTML;
You have send to this page this fields:<p>
<b>shopping Id</b>:
<pre>$shopping</pre><p>
<b>field params:</b>
<pre>$b</pre><p>
HTML

print end_html; 
