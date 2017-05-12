#!/home/ivan/bin/speedy
#!/home/ivan/bin/perl
#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../lib /home/ivan/perl);
use AnnoCPAN::XMLCGI;
use Template;
use AnnoCPAN::Config '../_config.pl';
use AnnoCPAN::Control;

AnnoCPAN::Control->new(
    cgi => AnnoCPAN::XMLCGI->new,
)->run;

