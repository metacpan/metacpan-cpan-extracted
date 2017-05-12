#!/perl -I..

use strict;
use lib 't';
use Test::More tests => 32;

eval <<'vScalarV';       # var scalar with a value
use vScalarV '$soda';
is $soda, 'Mountain Dew' => 'Scalar variable value';
eval q{$soda = 'Sprite'};
is $@,    ''             => 'Scalar variable is writeable';
is $soda, 'Sprite'       => 'Scalar write successful';
vScalarV
is $@,    ''             => 'Scalar variable use';

eval <<'vScalar';        # var scalar w/o value
use vScalar '$beer';
ok !defined($beer)       => 'Scalar variable valueless';
eval q{$beer = 'Weyerbacher'};
is $@,    ''             => 'null scalar is writeable';
is $beer, 'Weyerbacher'  => 'null scalar write successful';
vScalar
is $@,    ''             => 'null Scalar variable use';

eval <<'vArrayV';           # var array with value
use vArrayV '@bev';
is $bev[0], 'Mountain Dew'  => 'Array variable value 1';
is $bev[1], 'Weyerbacher'   => 'Array variable value 2';
is scalar @bev, 2           => 'Array variable value 3';
eval q{$bev[2] = 'Captain Morgan'};
is $@,      ''              => 'Array is writeable';
is scalar @bev, 3           => 'Array assignment 1';
is $bev[2], 'Captain Morgan'=> 'Array assignment 2';
vArrayV
is $@,      ''              => 'Array variable use';

eval <<'vArray';             # var array without value
use vArray '@bev2';
is scalar @bev2, 0           => 'empty Array variable value';
eval q{push @bev2, 'Captain Morgan'};
is $@,       ''              => 'empty Array is writeable';
is scalar @bev2, 1           => 'empty Array assignment 1';
is $bev2[0], 'Captain Morgan'=> 'empty Array assignment 2';
vArray
is $@,       ''              => 'empty Array variable use';

eval <<'vHashV';               # var hash with value
use vHashV '%bev';
is $bev{soda}, 'Mountain Dew'  => 'Hash variable value 1';
is $bev{beer}, 'Weyerbacher'   => 'Hash variable value 2';
is scalar keys %bev, 2         => 'Hash variable value 3';
eval q{$bev{rum} = 'Captain Morgan'};
is $@,      ''                 => 'Hash is writeable';
is scalar keys %bev, 3         => 'Hash assignment 1';
is $bev{rum}, 'Captain Morgan' => 'Hash assignment 2';
vHashV
is $@,      ''                 => 'Hash variable use';

eval <<'vHash';                  # var hash without value
use vHash '%bev2';
is scalar keys %bev2, 0          => 'empty Hash variable value';
eval q{$bev2{rum} = 'Captain Morgan'};
is $@,       ''                  => 'empty Hash is writeable';
is scalar keys %bev2, 1          => 'empty Hash assignment 1';
is $bev2{rum}, 'Captain Morgan'  => 'empty Hash assignment 2';
vHash
is $@,       ''                  => 'empty Hash variable use';

