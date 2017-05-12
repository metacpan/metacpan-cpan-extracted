package K;

use strict;
use warnings;

use Test::More tests => 14;

use_ok('Class::Accessor::Lite');

Class::Accessor::Lite->mk_accessors(qw(foo bar));
Class::Accessor::Lite->mk_ro_accessors(qw(ro));
Class::Accessor::Lite->mk_wo_accessors(qw(wo));

ok(! $@, 'call mk_accessors');

my $k = bless { foo => 1, bar => 2, ro => 3, wo => 4 }, 'K';
is($k->foo, 1);
is($k->foo(2), 2);
is($k->foo, 2);
is_deeply($k->foo(2, 3), [ 2, 3 ]);
is_deeply($k->foo, [ 2, 3 ]);
is($k->bar, 2);
is($k->ro, 3);
eval { $k->ro(99) };
my $e = $@;
like $e, qr{'K' cannot access the value of 'ro' on objects of class 'K' at t/00-base.t line };
$k->wo(801);
is $k->{wo}, '801';
is_deeply($k->wo(2, 3), [ 2, 3 ]);
eval { $k->wo() };
$e = $@;
ok $e;
like $e, qr{'K' cannot alter the value of 'wo' on objects of class 'K' at t/00-base.t line };

