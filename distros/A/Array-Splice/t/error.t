#!perl
use strict;
use warnings;

use Test::More tests => 4;

use Array::Splice qw ( splice_aliases );

my @array = (1,2,3);
my $scalar;

eval 'splice_aliases @array';
like ( $@, qr/^Not enough arguments/,'One argument');

eval 'splice_aliases @array,1';
like ( $@, qr/^Not enough arguments/,'Two argument');

eval 'splice_aliases $scalar,1,1';
like ( $@, qr/^Type of arg/,'Type of argument');

my $warning;
local $SIG{__WARN__} = sub { $warning = shift };

eval{ splice_aliases @array,5,1 };
like ( $warning, qr/ offset past end of array /,'Offset past end of array');
