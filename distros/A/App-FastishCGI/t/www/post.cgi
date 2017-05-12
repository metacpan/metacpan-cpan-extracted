#!/usr/bin/env perl

use strict;
use warnings;

use YAML::Any;
use CGI;

my $q = CGI->new;

print $q->header
 . $q->start_html
 . $q->h1('Hello ' . $q->param('fname'))
 . "<hr>"
 . $q->h2('POST Dump');

print "<blockquote>" . Dump($q->Vars) . "</blockquote>";


