use strict;
use warnings;
use lib 't/lib';
use Test2::V0;

plan tests => 1;

like(
   dies { 
      require TestSchema2; 
   },
   qr/is the same word in both singular/,
   'Attempt to use a schema where singular and plural are the same word dies'
);

