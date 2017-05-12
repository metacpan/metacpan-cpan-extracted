#!/home/ivan/bin/speedy
#!/home/ivan/bin/perl
#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../lib /home/ivan/perl);
use CGI;
use CGI::Carp 'fatalsToBrowser';
use Template;
use AnnoCPAN::Config '../_config.pl';
use AnnoCPAN::Control;

$ENV{QUERY_STRING} = 
        'mode=search;field=Module;latest=1;redirect=1;name=' . $ENV{QUERY_STRING}; 

AnnoCPAN::Control->new->run;

