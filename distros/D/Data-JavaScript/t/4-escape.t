#!/usr/bin/env perl

use Modern::Perl;

use Test2::V0;

use Data::JavaScript;

use Readonly;
Readonly my $NEGATIVE_ONE => -1;
Readonly my $PI           => 3.14159;

#Test numbers: negative, real, engineering, octal/zipcode
is join( q//, jsdump( 'ixi', $NEGATIVE_ONE ) ), 'var ixi = -1;', 'Integer -1';

is join( q//, jsdump( 'pi', $PI ) ), 'var pi = 3.14159;', 'Pi';

is join( q//, jsdump( 'c', '3E8' ) ), 'var c = 3E8;', 'Scientific notation';

is join( q//, jsdump( 'zipcode', '02139' ) ),
  'var zipcode = "02139";',
  'US ZIP code';

is join( q//, jsdump( 'hex', '0xdeadbeef' ) ),
  'var hex = "0xdeadbeef";',
  'Hexadecimal';

## no critic (RequireInterpolationOfMetachars)
is join( q//, jsdump( 'IEsux', '</script>DoS!' ) ),
  'var IEsux = "\x3C\x2Fscript\x3EDoS!";',
  'Entity encoding.';

done_testing;
