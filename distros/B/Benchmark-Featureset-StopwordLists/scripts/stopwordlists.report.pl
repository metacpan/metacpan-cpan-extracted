#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark::Featureset::StopwordLists;

# ---------------------------------------

Benchmark::Featureset::StopwordLists -> new -> run;
