use strict;
use warnings;
use Test::More tests => 10;
use Scalar::Util qw(blessed reftype);

BEGIN {
    use_ok('Acme::Curse');
}
Acme::Curse->import('curse');


my $h = bless {};
ok blessed($h),             'Basic sanity';

ok !blessed(curse($h)),     'Can curse hash ref';
is reftype($h), 'HASH',     'Cursing a hash ref results in a hash ref';

my $a = bless [];
ok !blessed(curse($a)),     'Can curse array ref';
is reftype($a), 'ARRAY',    'Cursing an array ref results in an array ref';

my $b = 1;
my $s = bless \$b;
ok !blessed(curse($s)),     'Can curse scalar ref';
is reftype($s), 'SCALAR',   'Cursing a scalar ref results in a scalar ref';

my $c = bless sub {1};
ok !blessed(curse($c)),     'Can curse code ref';
is reftype($c), 'CODE',     'Cursing a code ref results in a code ref';
