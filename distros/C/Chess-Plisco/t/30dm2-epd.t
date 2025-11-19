#! /usr/bin/env perl

# Copyright (C) 2018 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Cwd qw(abs_path);
use File::Basename qw(dirname);

use lib 't/lib';

use EPDSolver;

use Chess::Plisco::EPD;

my $t_dir = dirname abs_path __FILE__;
my $epd_file = "$t_dir/epd/dm2.epd";

my $limit;
if ($ENV{CP_STRESS_TEST}) {
	$limit = $ENV{CP_STRESS_TEST};
} else {
	$limit = 50;
}

EPDSolver->new($epd_file, $limit, pseudo_legal => 1)->solve;
