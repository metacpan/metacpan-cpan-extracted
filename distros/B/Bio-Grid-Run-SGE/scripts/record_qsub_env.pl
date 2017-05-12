#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Carp;

use Bio::Gonzales::Util::Cerial;

yspew("env.yml", \%ENV);
