#!/usr/bin/env perl

use strict;
use warnings;

use feature qw(say);

our $VERSION = "0.01";

use lib 't/lib';
use Data::Dumper qw(Dumper);

require 'Other.pl';    # does exist in t/lib
require Dummy;         # does not exist

exit;
