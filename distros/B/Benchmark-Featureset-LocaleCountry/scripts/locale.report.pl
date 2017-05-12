#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark::Featureset::LocaleCountry;

# ---------------------------------------

Benchmark::Featureset::LocaleCountry -> new -> run;
