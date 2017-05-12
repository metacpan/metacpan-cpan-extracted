#!/usr/bin/perl

package TestApp;
use base 'Class::DBI';

use strict;
use warnings;

use Test::More tests => 1;


use_ok ( 'Class::DBI::Plugin::Pager::LimitOffset' );




