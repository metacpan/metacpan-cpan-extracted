# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::InflateColumn::Serializer' );
}



#my $object = DBIx::Class::Inflator::Serializers->new ();
#isa_ok ($object, 'DBIx::Class::Inflator::Serializers');


