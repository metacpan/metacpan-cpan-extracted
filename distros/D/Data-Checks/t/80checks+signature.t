#!/usr/bin/perl

use v5.22;
use warnings;

use Test2::V0;

BEGIN {
   plan skip_all => "Data::Checks >= 0.02 is not available"
      unless eval { require Data::Checks;
                    Data::Checks->VERSION( '0.02' ) };
   plan skip_all => "Signature::Attribute::Checked >= 0.04 is not available"
      unless eval { require Signature::Attribute::Checked;
                    Signature::Attribute::Checked->VERSION( '0.04' ) };

   Data::Checks->import(qw( Defined ));
   Signature::Attribute::Checked->import;

   diag( "Data::Checks $Data::Checks::VERSION, " .
         "Signature::Attribute::Checked $Signature::Attribute::Checked::VERSION" );
}

# We know this must be available since Signature::Attribute::Checked would
# depend on it
use Sublike::Extended;
use experimental qw( signatures );

extended sub func ( $x :Checked(Defined) ) { return $x }

is( func(123), 123, 'func() accepts defined argument' );
ok( dies { func(undef) }, 'fails with undefined argument' );
# Don't be overly sensitive on the format of the message, in case it changes.
# It's just for human interest

done_testing;
