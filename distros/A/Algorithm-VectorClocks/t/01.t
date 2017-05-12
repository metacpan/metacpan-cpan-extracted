use strict;
use warnings;
use Test::More tests => 27;

use Algorithm::VectorClocks;
use JSON::Any;

my $json = JSON::Any->new;

my $vc_a = Algorithm::VectorClocks->new;
is_deeply $vc_a->clocks, {};

my $vc_b = Algorithm::VectorClocks->new;
my $vc_c = Algorithm::VectorClocks->new;

### in server A ###

Algorithm::VectorClocks->id('A');

$vc_a->increment;
is_deeply $vc_a->clocks, { A => 1 };

my $serialized_a = $vc_a->serialize;
is_deeply $json->jsonToObj($serialized_a), { A => 1 };

### in server B ###

Algorithm::VectorClocks->id('B');

$vc_b->merge($serialized_a);
is_deeply $vc_b->clocks, { A => 1 };

$vc_b++;
is_deeply $vc_b->clocks, { A => 1, B => 1 };

my $serialized_b = "$vc_b";

### in server A ###

Algorithm::VectorClocks->id('A');

$vc_a += $serialized_b;
is_deeply $vc_a->clocks, { A => 1, B => 1 };

$vc_a++;
is_deeply $vc_a->clocks, { A => 2, B => 1 };

$serialized_a = "$vc_a";

ok   $vc_b == $serialized_b;
ok   $vc_b eq $serialized_b;
ok !($vc_b != $serialized_b);
ok !($vc_b ne $serialized_b);

### in server C ###

Algorithm::VectorClocks->id('C');

ok !$vc_b->equal($serialized_a);
ok  $vc_b->not_equal($serialized_a);

$vc_c += $serialized_b;
is_deeply $vc_c->clocks, { A => 1, B => 1 };

$vc_c++;
is_deeply $vc_c->clocks, { A => 1, B => 1, C => 1 };

my $serialized_c = "$vc_c";

### in client ###

my @res = order_vector_clocks({ A => $serialized_a });
is @res, 1;
is $res[0], 'A';

@res = order_vector_clocks({ A => $serialized_a, B => $serialized_b });
is @res, 2;
is $res[0], 'A';
is $res[1], 'B';

@res = order_vector_clocks({ C => $serialized_c, A => $serialized_a });
is @res, 1;
like $res[0][0], qr/^[AC]$/;
like $res[0][1], qr/^[AC]$/;

@res = order_vector_clocks({ A => $serialized_a, B => $serialized_b, C => $serialized_c });
is @res, 2;
like $res[0][0], qr/^[AC]$/;
like $res[0][1], qr/^[AC]$/;
is $res[1], 'B';
