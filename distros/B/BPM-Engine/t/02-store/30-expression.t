use strict;
use warnings;
use Test::More;
use Test::Exception;
use t::TestUtils;

BEGIN { use_ok('BPM::Engine::Util::ExpressionEvaluator'); }

#------------------------------------------------------------------------
# setting (render)
# <InitialValue>
#
# rendering
# <Script>
# output = ...
#
# getting
# <ActualParameter>sbflw1.data</ActualParameter>
#
# setting
# <Target>product.prices[0..2]</Target>
# <Expression>attribute('tt_hash').prices.0 + 10</Expression>
#
# evalling
# <Condition Type="CONDITION">attribute.counter > 3</Condition>
#------------------------------------------------------------------------

#-- setup a test process_instance

my $xml = q|
|;

my ($engine, $process) = process_wrap($xml);
my $pi = $process->new_instance();

$pi->add_to_attributes({
    name           => 't_string',
    scope          => 'fields',
    type           => 'BasicType',
    value          => ['A String'],
    });

$pi->add_to_attributes({
    name           => 't_hash',
    scope          => 'fields',
    type           => 'SchemaType',
    value          => {
        id     => 10,
        desc   => 'Some Product',
        prices => ['66.60',88.80]
        },
    });

$pi->add_to_attributes({
    name           => 't_array',
    scope          => 'fields',
    type           => 'SchemaType',
    is_array => 1,
    value          => [{ store => { bicycle => 'Gazelle' } }]
    });

#-- constructor -------------------------------------------

throws_ok(sub { BPM::Engine::Util::ExpressionEvaluator->load() }, 'BPM::Engine::Exception::Parameter', 'Invalid arguments');
throws_ok(sub { BPM::Engine::Util::ExpressionEvaluator->load() }, qr/Need a process instance/, 'Invalid arguments');

throws_ok(sub { BPM::Engine::Util::ExpressionEvaluator->load(some => 'stuff', process_instance => $pi) }, 'BPM::Engine::Exception::Parameter', 'Invalid arguments');
throws_ok(sub { BPM::Engine::Util::ExpressionEvaluator->load(some => 'stuff', process_instance => $pi) }, qr/Invalid ExpressionEval arguments/, 'Invalid arguments');

ok(my $xe = BPM::Engine::Util::ExpressionEvaluator->load(
    process_instance => $pi,
    ));
isa_ok($xe,'BPM::Engine::Util::Expression::Xslate');

#-- type --------------------------------------------------

is($xe->type, 'xslate');

#-- params ------------------------------------------------
#-- get_param, set_param, variables, set_activity

is_deeply([sort $xe->variables],[qw/arguments attribute process_instance var/]);
is($xe->get_param('process_instance')->{process_id}, $process->id);
throws_ok(sub { $xe->set_param('foo') }, qr/Cannot call set without at least 2 arguments/, 'Invalid arguments');
ok($xe->set_param('foo',[]));
ok($xe->set_param('bar', { x => 'y' }));
is($xe->get_param('bar')->{x}, 'y');
is_deeply([sort $xe->variables],[qw/arguments attribute bar foo process_instance var/]);
my $activity = $process->add_to_activities({})->discard_changes;
is($activity->activity_type,'Implementation');
$xe->set_activity($activity->TO_JSON);
is_deeply([sort $xe->variables],[qw/activity arguments attribute bar foo process_instance var/]);
is($xe->get_param('activity')->{activity_id}, $activity->id);

#warn Dumper $xe->params->{activity};

#-- render ------------------------------------------------

if(0){
#local $TODO = 'output with brackets';
#warn "RES " . $xe->render("[% count + counter %]");
is($xe->render(" attribute('t_hash').desc "),'Some Product');
is($xe->render(" attribute('t_hash').id == 10 "),1);
ok(!$xe->render("[% attribute('t_hash').id == 11 %]"));
is($xe->render("[% attribute('t_string') == 'A String' %]"),1);
ok(!$xe->render("[% attribute('t_string') == 'Some String' %]"));
is($xe->render("[% attribute('t_string') %]"),'A String');
# no ${} interpolation
is($xe->render(q/[% ph = attribute('t_hash').prices.1 %][% "Price is ${ph} " _ attribute('t_hash').prices.0 _ ph %]/),'Price is $(ph) 66.6088.8');
}

my $ve = $xe->render(
"[% th = {
            id     => 'XYZ-2000',
            desc   => 'Bogon Generator',
            prices => [66.60, 88],
            bike   => attribute('t_array').0.store.bicycle
          }; output(th) %]");
is($ve->{desc},'Bogon Generator');
is($ve->{bike},'Gazelle');

#-- evaluate ----------------------------------------------

is($xe->evaluate(1), 1);
is($xe->evaluate(0), 0);
is($xe->evaluate('0'), 0);
is($xe->evaluate(undef), 0);
is($xe->evaluate(), 0);
is($xe->evaluate(''), 0);


#is($xe->evaluate(0.0), 0);
#is($xe->evaluate('0.0'), 0);

is($xe->evaluate('false'), 0);
is($xe->evaluate('true'), 1);

#- depends on Xslate level setting
#is($xe->evaluate('NULL'), 0);
#throws_ok(sub { $xe->evaluate('NULL') },  'BPM::Engine::Exception::Expression');
#throws_ok(sub { $xe->evaluate('NULL') },  qr/Invalid template syntax: Text::Xslate: Use of nil/);

#is($xe->evaluate('null'), 0);
is($xe->evaluate('NOT NULL'), 1);
is($xe->evaluate('not nULl'), 1);
is($xe->evaluate('!NULL'), 1);
is($xe->evaluate('!1'), 0);
is($xe->evaluate('!0'), 1);

is($xe->evaluate(" attribute('t_hash').id == 10"),1);
is($xe->evaluate("attribute('t_hash').id == 11 "),0);

is($xe->evaluate("[% attribute('t_hash').id == 10 %]"),1);
is($xe->evaluate("[% attribute('t_hash').id == 11 %]"),0);
is($xe->evaluate("[% attribute('t_string') == 'A String' %]"),1);
is($xe->evaluate("[% attribute('t_hash').prices.1 > 77 ? 1 : 0 %]"),1);

$pi->add_to_attributes({
    name           => 'splitA',
    scope          => 'fields',
    type           => 'BasicType',
    is_array       => 0,
    value          => undef
    });
is($xe->evaluate("!attribute('splitA') OR attribute('splitA') == 'B1'"),1);
$pi->attribute(splitA => 'C');
is($xe->evaluate("!attribute('splitA') OR attribute('splitA') == 'B1'"),0);
$pi->attribute(splitA => 'B1');
is($xe->evaluate("!attribute('splitA') || attribute('splitA') == 'B1'"),1);

is($xe->evaluate("attribute('splitA').search('B')"),1);
is($xe->evaluate("attribute('splitA').search('B1')"),1);
is($xe->evaluate("attribute('splitA').search('C')"),0);

is($xe->evaluate('1 + 2 - 3'),0);

throws_ok(sub { $xe->evaluate(3) }, qr/not boolean/);
throws_ok(sub { $xe->evaluate(3) }, 'BPM::Engine::Exception::Expression');

throws_ok(sub { $xe->evaluate('Some string') }, qr/Expected a semicolon or block end, but got 'string'/);
throws_ok(sub { $xe->evaluate('Some string') }, 'BPM::Engine::Exception::Expression');

throws_ok(sub { $xe->evaluate('"Some string"') }, qr/not a number/);
throws_ok(sub { $xe->evaluate('"Some string"') }, 'BPM::Engine::Exception::Expression');

#-- assign ------------------------------------------------

is($pi->attribute('t_string')->value, 'A String');

if(0) {
local $TODO = 'output with brackets';
$xe->assign('t_string', "Hello [% attribute('t_string') %]World");
is($pi->attribute('t_string')->value, 'Hello A StringWorld');
}

$xe->assign('t_string', "Hello [% output('Goodbye Planet') %]World");
is($pi->attribute('t_string')->value, 'Goodbye Planet');

is($pi->attribute('t_hash')->value->{id}, 10);
$xe->assign('t_hash.id', 'Hello [% output(15) %] World');
is($pi->attribute('t_hash')->value->{id}, 15);

$xe->assign('t_hash.id', '"14"');
is($pi->attribute('t_hash')->value->{id}, 14);

is($pi->attribute('t_hash')->value->{prices}->[1], 88.8);
is($pi->attribute('t_hash')->value->{prices}->[1], '88.8');
$xe->assign('t_hash.prices.1', '"89"');
is($pi->attribute('t_hash')->value->{prices}->[0], '66.60');
is($pi->attribute('t_hash')->value->{prices}->[1], 89);

#$xe->assign('t_hash', '[% { id => 16 } %]');
is($pi->attribute('t_hash')->value->{id}, 14);

$xe->assign('t_hash', '[% output({ id => 18, foo => "bar" }) %]');
$xe->assign('t_hash.desc','"baz"');
is($pi->attribute('t_hash')->value->{id}, 18);
is($pi->attribute('t_hash')->value->{foo}, 'bar');
is($pi->attribute('t_hash')->value->{desc}, 'baz');

$xe->assign('t_hash', "[% output({ id => 'XYZ-2000', desc => 'Bogon Generator',
            prices => [66.60, 88],
            bike   => attribute('t_array').0.store.bicycle
            }) %]");
is($pi->attribute('t_hash')->value->{desc}, 'Bogon Generator');

done_testing;
