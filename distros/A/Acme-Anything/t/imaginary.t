#!perl
use Test::More tests => 2;

require Acme::Anything;
pass( 'Loaded Acme::Anything' );

require An::Unlikely::Occurrance;
pass( 'Loaded An::Unlikely::Occurrance' );
