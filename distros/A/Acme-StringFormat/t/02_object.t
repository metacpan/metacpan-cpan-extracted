#!perl

use strict;
use warnings;

use Test::More tests => 4;

use Math::BigInt;
use Math::BigFloat;

use Acme::StringFormat;

is '[%d]'    % Math::BigInt->new(10),    '[10]',   'fmt % bigint';
is '[%.02f]' % Math::BigFloat->new(0.1), '[0.10]', 'fmt % bigfloat';

use bignum;

is '[%d]'    % 10,  '[10]',   'fmt % bigint';
is '[%.02f]' % 0.1, '[0.10]', 'fmt % bigfloat';
