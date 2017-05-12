#!/usr/bin/env perl
use Dancer;
set environment => "dancer1";
use FindBin;
use lib ("$FindBin::Bin/../lib");
use lib ("$FindBin::Bin/../../../lib");
use lib ("$FindBin::Bin/../../../frameworks/Dancer1/lib");

use Dancer::Plugin::Articulate;
my $app = articulate_app;
$app->enable;
dance;
