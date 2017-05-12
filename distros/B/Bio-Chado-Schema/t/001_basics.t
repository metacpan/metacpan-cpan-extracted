#!/usr/bin/perl
use strict;
use warnings;
use FindBin;

use Test::More tests => 1;
use lib "$FindBin::RealBin/lib";
use Bio::Chado::Schema::Test;

my $schema = Bio::Chado::Schema::Test->init_schema();
isa_ok( $schema, 'DBIx::Class::Schema' );
