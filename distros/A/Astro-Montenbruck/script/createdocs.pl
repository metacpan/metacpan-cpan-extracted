#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw/$Bin/;

use Pod::Simple::HTMLBatch;
use Pod::Simple::XHTML;

our $VERSION = 0.01;

my $docs_dir = "$Bin/../docs";
unless (-e $docs_dir) {
    mkdir $docs_dir or die "could not create directory: $!";
}


my $convert = Pod::Simple::HTMLBatch->new;
#$convert->html_render_class('Pod::Simple::XHTML');
#$convert->add_css('http://www.perl.org/css/perl.css');
#$convert->perldoc_url_prefix('./');
$convert->batch_convert("$Bin/../lib", $docs_dir);
