#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use if -d "$FindBin::RealBin/../lib/App"
  , lib => "$FindBin::RealBin/../lib";

use App::oo_modulino_zsh_completion_helper -as_base;

MY->cli_run(\@ARGV, {0 => 'zero'});
