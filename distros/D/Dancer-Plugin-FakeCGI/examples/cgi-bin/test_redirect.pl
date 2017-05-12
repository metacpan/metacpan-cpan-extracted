#!/usr/bin/perl –w
#
use strict;

#use CGI::Carp qw(:fatalsToBrowser);
use CGI::Carp qw(fatalsToBrowser);
use CGI qw(:standard);

print redirect(param('location'));
