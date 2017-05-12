#!/usr/bin/perl

use lib '../blib/lib';
use strict;
use Apache::Htpasswd::Perishable;

my $passwd = Apache::Htpasswd::Perishable->new('.htpasswd');
   $passwd->htpasswd("zog", "password");
   $passwd->expire("zog",31);
   $passwd->extend("zog",10);
