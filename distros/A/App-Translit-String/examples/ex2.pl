#!/usr/bin/env perl

use strict;
use warnings;

use App::Translit::String;

# Run.
@ARGV = ('Российская Федерация');
exit App::Translit::String->new->run;

# Output:
# Rossijskaâ Federaciâ