#!/usr/bin/perl

use strict;
use warnings;

exec qw(socat stdio TCP:localhost:8022);
