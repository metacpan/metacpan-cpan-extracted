#!/usr/bin/env perl

use strict;
use warnings;

use lib qw( ./lib );

use Test::More tests => 2;

BEGIN { use_ok( 'DateTime::Format::x509' ); }

my $obj = DateTime::Format::x509->new;
isa_ok($obj, 'DateTime::Format::x509');
