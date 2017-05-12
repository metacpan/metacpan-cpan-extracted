#!/usr/bin/perl

# Copyright (C) 2003-2005  Joshua Hoblitt

use strict;
use warnings;

use lib qw( ./lib );

use Test::More tests => 2;

BEGIN { use_ok( 'DateTime::Format::ISO8601' ); }

my $object = DateTime::Format::ISO8601->new;
isa_ok( $object, 'DateTime::Format::ISO8601' );
