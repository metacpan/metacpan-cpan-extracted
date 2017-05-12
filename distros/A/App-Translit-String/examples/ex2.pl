#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use App::Translit::String;

# Run.
@ARGV = ('Российская Федерация');
App::Translit::String->new->run;

# Output:
# Rossijskaja Federacija