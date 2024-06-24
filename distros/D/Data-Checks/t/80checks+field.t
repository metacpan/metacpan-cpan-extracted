#!/usr/bin/perl

use v5.22;
use warnings;

use Test2::V0;

BEGIN {
   plan skip_all => "Data::Checks >= 0.02 is not available"
      unless eval { require Data::Checks;
                    Data::Checks->VERSION( '0.02' ) };
   plan skip_all => "Object::Pad::FieldAttr::Checked >= 0.10 is not available"
      unless eval { require Object::Pad::FieldAttr::Checked;
                    Object::Pad::FieldAttr::Checked->VERSION( '0.10' ) };

   Data::Checks->import(qw( Defined ));
   Object::Pad::FieldAttr::Checked->import;

   diag( "Data::Checks $Data::Checks::VERSION, " .
         "Object::Pad::FieldAttr::Checked $Object::Pad::FieldAttr::Checked::VERSION" );
}

# We know this must be available since Object::Pad::FieldAttr::Checked would
# depend on it
use Object::Pad;

class TestClass {
   field $x :param :reader :Checked(Defined);
}

is( TestClass->new( x => 123 )->x, 123, 'Field $x accepts defined argument' );
ok( dies { TestClass->new( x => undef ) }, 'fails with undefined argument' );
# Don't be overly sensitive on the format of the message, in case it changes.
# It's just for human interest

done_testing;
