#!/usr/bin/env perl

use lib qw( ./Dancer/lib ./lib ./t );
use Dancer;

load_app 'Sample';

dance;
