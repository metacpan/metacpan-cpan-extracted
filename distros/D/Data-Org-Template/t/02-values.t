#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
$Data::Dumper::Useqq = 1;

use Data::Org::Template;
use Iterator::Records;

my $t;

$t = Data::Org::Template->new("Hello, [[name]]!");

my $g = $t->data_getter({name => 'world'});
isa_ok ($g, 'Data::Org::Template::Getter');
is ($g->get('name'), 'world', 'basic lookup');

my $context = ['test value', {'.count' => 42}, '*'];
is ($g->get('name', $context), 'world', 'context lookup');
is ($g->get('.count', $context), '42', 'hashref from context');
is ($g->get('.', $context), 'test value', 'scalar from context');
is ($g->get('blargh', $context), undef, 'not in context');

$context = ['<html>', $context];
is ($g->get('name', $context), 'world', 'nested context lookup');
is ($g->get('.', $context), '<html>', 'scalar from nested context');
is ($g->get('.|html', $context), '&lt;html&gt;', 'formatted value'); # Worked first try. Damn I'm good.
is ($g->get('.| html', $context), '&lt;html&gt;', 'formatted value with spacing');
is ($g->get('. | html', $context), '&lt;html&gt;', 'formatted value with spacing');
is ($g->get('. | html 49', $context), '&lt;html&gt;', 'formatted value with parm');





done_testing();
