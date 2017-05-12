#!/perl -I..

use strict;
use lib 't';
use Test::More tests => 28;

# Is Readonly available?
my $rok;
BEGIN { eval 'use Readonly'; $rok = $@? 0 : 1; }
my $err = qr/^Modification of a read-only value attempted at \(eval /;

eval <<'rScalarV';       # ro scalar with a value
use rScalarV '$soda';
is $soda, 'Mountain Dew' => 'Scalar variable value';
SKIP: {
skip 'Readonly not available', 2  unless $rok;
eval q{$soda = 'Sprite'};
like $@,  $err           => 'Scalar variable not writeable';
is $soda, 'Mountain Dew' => 'Scalar write unsuccessful';
}
rScalarV
is $@,    ''             => 'Scalar variable use';

eval <<'rScalar';        # ro scalar w/o value
use rScalar '$beer';
ok !defined($beer)       => 'Scalar ro variable valueless';
SKIP: {
skip 'Readonly not available', 2  unless $rok;
eval q{$beer = 'Weyerbacher'};
like $@,       $err      => 'null scalar not writeable';
ok !defined($beer)       => 'null scalar write unsuccessful';
}
rScalar
is $@,    ''             => 'null Scalar ro variable use';

eval <<'rArrayV';           # ro array with value
use rArrayV '@bev';
is scalar @bev, 2           => 'ro Array value 1';
is $bev[0], 'Mountain Dew'  => 'ro Array value 2';
is $bev[1], 'Weyerbacher'   => 'ro Array value 3';
SKIP: {
skip 'Readonly not available', 2  unless $rok;
eval q{$bev[2] = 'Captain Morgan'};
like $@,           $err     => 'ro Array is not writeable';
is scalar @bev, 2           => 'ro Array assignment';
}
rArrayV
is $@,      ''              => 'ro Array variable use';

eval <<'rArray';             # ro array without value
use rArray '@bev2';
is scalar @bev2, 0           => 'empty ro Array value';
SKIP: {
skip 'Readonly not available', 2 unless $rok;
eval q{push @bev2, 'Captain Morgan'};
like $@,      $err           => 'ro Array is not writeable';
is scalar @bev2, 0           => 'ro Array assignment';
}
rArray
is $@,       ''              => 'empty Array variable use';

eval <<'rHashV';               # ro hash with value
use rHashV '%bev';
is $bev{soda}, 'Mountain Dew'  => 'ro Hash value 1';
is $bev{beer}, 'Weyerbacher'   => 'ro Hash value 2';
is scalar keys %bev, 2         => 'ro Hash value 3';
SKIP: {
skip 'Readonly not available', 2  unless $rok;
eval q{$bev{rum} = 'Captain Morgan'};
like $@,       $err            => 'ro Hash is not writeable';
is scalar keys %bev, 2         => 'ro Hash assignment';
}
rHashV
is $@,      ''                 => 'ro Hash use';

eval <<'rHash';                  # ro hash without value
use rHash '%bev2';
is scalar keys %bev2, 0          => 'empty ro Hash value';
SKIP: {
skip 'Readonly not available', 2 unless $rok;
eval q{$bev2{rum} = 'Captain Morgan'};
like $@,       $err              => 'ro empty Hash is not writeable';
is scalar keys %bev2, 0          => 'ro empty Hash assignment';
}
rHash
is $@,       ''                  => 'ro empty Hash use';

