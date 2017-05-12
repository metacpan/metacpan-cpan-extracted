#! /usr/bin/env perl

use 5;
use warnings;
use strict;

use FindBin;
use vars qw($TEST);
$TEST = __FILE__ ;

do "$FindBin::Bin/test.pl" || die;

exit;

