#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;

use_ok('Bash::Completion::Request')
  or die "Could not load 'Bash::Completion::Request', ";

$ENV{COMP_LINE}  = 'abcd efgh word';
$ENV{COMP_POINT} = 12;
my $r = Bash::Completion::Request->new;

ok($r, 'Created Request instance ok');
is($r->line,  'abcd efgh word', '... expected command line');
is($r->word,  'wo',             '... expected parsed word');
is($r->point, 12,               '... expected point value');

is($r->count, 3, '... correct number of parsed arguments');
cmp_deeply([$r->args], [qw(abcd efgh wo)], '... and the expected arguments');

ok($r->can('candidates'), 'Request accepts method candidates()');

$r->candidates('a', 'b', 'c');
cmp_deeply([$r->candidates], [qw( a b c )], 'candidates() work as expected');

done_testing();
