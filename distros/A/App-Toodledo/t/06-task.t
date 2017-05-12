#!perl
use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;

my $CLASS;
my $USERID = 'username';
my $APPID  = 'MyApp';

BEGIN { $CLASS = 'App::Toodledo::Task'; use_ok $CLASS }
