#!/usr/bin/perl

use lib '/home/web/tobix/Modules/';
use DBIx::CGITables;

my %parameters=();

my $query=DBIx::CGITables->new(\%parameters);

# Maybe it's better to put this line in the templates? Think about
# it!  Often text/plain works out as well.  And maybe you would
# like to make scripts that outputs graphics?  (then again,
# another template engine should be considered) 

print "Content-Type: text/html\n\n";

$query->search_execute_and_do_everything_even_parse_the_template();

