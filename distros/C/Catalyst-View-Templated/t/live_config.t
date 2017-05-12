#!/usr/bin/env perl

BEGIN { $ENV{TEMPLATED_USE_CONFIG} = 'good idea' };

use strict;
use warnings;
use Test::More tests => 2;
use Storable qw/thaw/;

use FindBin qw($Bin);
use lib "$Bin/lib";
use Test::WWW::Mechanize::Catalyst 'TestApp';

no warnings 'once';
local $Storable::Deparse = 1; 
local $Storable::Eval = 1;

my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/action_detach');
my $content = $mech->content;

is thaw($content)->{'action_detach.template'}{action}, 'detach',
  'used action name as template name ok, with extension';
