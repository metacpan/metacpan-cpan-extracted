#! /usr/bin/perl -w
use strict;

use FindBin;
use lib "$FindBin::Bin";
use lib "$FindBin::Bin/../lib";

use MyApp;

#MyApp->to_app();

use Dancer2;
dance();
