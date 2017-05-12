#!perl -T
#
# This file is part of DBIx-Class-InflateColumn-Serializer-CompressJSON
#
# This software is copyright (c) 2012 by Weborama.  No
# license is granted to other entities.
#

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::InflateColumn::Serializer::CompressJSON' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Class::InflateColumn::Serializer::CompressJSON $DBIx::Class::InflateColumn::Serializer::CompressJSON::VERSION, Perl $], $^X" );
