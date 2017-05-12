#!perl -w

use strict;
use Test::More tests =>7;

use Data::Util qw(anon_scalar);

my $sref = \do{ my $anon };

is_deeply anon_scalar(), $sref, 'anon_scalar';
is_deeply anon_scalar(undef), $sref, 'anon_scalar';

is_deeply anon_scalar(10), \10;
is_deeply anon_scalar('foo'), \'foo';

ok !Internals::SvREADONLY(${ anon_scalar(10) }), 'not readonly';

my $foo;

# equivalent to "$foo = \do{ my $tmp = $foo }"
$foo = anon_scalar $foo;

is_deeply $foo, $sref;

ok eval{ ${anon_scalar()} = 10; }, 'writable';
