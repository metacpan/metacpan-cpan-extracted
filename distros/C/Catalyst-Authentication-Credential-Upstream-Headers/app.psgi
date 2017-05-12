#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use TestApp;

TestApp->setup_engine("PSGI");

my $app = sub { TestApp->run(@_) };
