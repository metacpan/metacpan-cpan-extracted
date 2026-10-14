#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($zeta $alpha $mid $unset);

my $ctx;
sub fill { $zeta = 'z'; $alpha = 'a'; $mid = 'm'; $ctx = Context::Vars->capture }
fill();

is_deeply([$ctx->names], [qw(alpha mid zeta)], 'names are sorted and without the sigil');
is(scalar(my @n = $ctx->names), 3, 'three of them');
is($ctx->get('alpha'), 'a', 'get by bare name');
is($ctx->get('$zeta'), 'z', 'get with the sigil');
ok(!defined $ctx->get('unset'), 'a variable with no value there gives undef');
ok(!defined $ctx->get('never_imported'), 'so does a name nobody imported');
is($alpha // 'undef', 'undef', 'get does not enter: the caller still reads its own');

my $v = $ctx->get('mid');
$v .= ' changed';
is($ctx->get('mid'), 'm', 'get returns a copy: changing it changes nothing');
ok(eval { $_ .= ' in place' for $ctx->get('mid'); 1 }, 'what get returns can be changed in place')
    or diag $@;
is($ctx->get('mid'), 'm', 'and that changes nothing in the context');

is_deeply([Context::Vars->capture->names], [], 'a capture with nothing set has no names');

sub many { $mid = $_ for 1 .. 3; my $r = \$zeta; Context::Vars->capture }
is_deeply([many()->names], [qw(mid)], 'only names with a value are listed');

done_testing;
