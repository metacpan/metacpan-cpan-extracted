use strict;
use Test::More;

use Class::Accessor::Inherited::XS inherited => [qw/a b c/];

my $o = bless {};

$o->{a} = 1;
is($o->a, 1, 'read obj attr');

$o->{b} = 5;
is($o->b, 5, 'read another obj attr');

is($o->a, 1, 'a is stil the same');

$o->c(42);
is($o->c, 42, 'read after obj setter');
is($o->{c}, 42, 'correct obj key');

done_testing;
