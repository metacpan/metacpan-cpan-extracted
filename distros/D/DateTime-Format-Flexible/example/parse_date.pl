#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Flexible;
my $dt = DateTime::Format::Flexible->parse_datetime( 'January 8, 1999' );

# $dt = a DateTime object set at 1999-01-08T00:00:00
