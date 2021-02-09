#!/usr/bin/env perl

use strict;
use warnings;

use App::Translit::String;

# Run.
@ARGV = ('-r', 'Rossijskaâ Federaciâ');
exit App::Translit::String->new->run;

# Output:
# Российская Федерация