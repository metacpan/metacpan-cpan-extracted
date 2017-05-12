#!/usr/bin/perl

###################################################################
# An example of a wrapper
#

use strict;
use warnings;

$ENV{'REQUEST_METHOD'} = 'GET';
$ENV{'QUERY_STRING'}   = 'choice=b';
do "./hello_world.cgi";
