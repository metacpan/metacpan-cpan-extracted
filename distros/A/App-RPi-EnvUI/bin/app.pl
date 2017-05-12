#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use App::RPi::EnvUI;
App::RPi::EnvUI->to_app;

