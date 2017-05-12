#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Test::PureASCII;

all_perl_files_are_pure_ascii(qw( lib t xt ));

