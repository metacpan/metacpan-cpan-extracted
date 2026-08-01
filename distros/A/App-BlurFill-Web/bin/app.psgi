#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use App::BlurFill::Web;

App::BlurFill::Web->to_app;
