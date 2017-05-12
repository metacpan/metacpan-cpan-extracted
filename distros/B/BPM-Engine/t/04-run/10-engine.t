use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Moose;
use XML::LibXML;
use t::TestUtils;
use BPM::Engine;

#-- Interface check
#----------------------------------------------------------------------------

schema();

my $e;

#- new

throws_ok(
    sub { BPM::Engine->new() },
    'BPM::Engine::Exception::Parameter',
    'Invalid connection arguments'
    );

lives_ok( sub { BPM::Engine->new( connect_info => $dsn ) }, 'Valid connect_info' );
lives_ok( sub { BPM::Engine->new({ connect_info => $dsn }) }, 'Valid connect_info' );
dies_ok(  sub { BPM::Engine->new( connect_info => {} ) }, 'Valid connect_info' );

#- logger

ok($e = BPM::Engine->new(
    connect_info => { dsn => $dsn },
    log_dispatch_conf => {
        class     => 'Log::Dispatch::Screen',
        min_level => 'critical',
        stderr    => 1,
        format    => '[%p] %m at %F line %L%n',
        },
    ));

#- new_with_config
{
local $SIG{__WARN__} = sub {};
if(-f '/etc/bpmengine/engine.yaml') {
    lives_ok( sub { BPM::Engine->new_with_config() }, 'Valid default config' );
    }
else {

  throws_ok(
    sub { BPM::Engine->new_with_config() },
    qr[Invalid connection arguments],
    'Invalid config file'
    );

  throws_ok(
    sub { BPM::Engine->new_with_config() },
    'BPM::Engine::Exception::Parameter',
    'Invalid config file'
    );

  ok($e = BPM::Engine->new_with_config(connect_info => $dsn));
    #qr[Specified configfile '/etc/bpmengine.yaml' does not exist],'Invalid config file'
    #like($e->connect_info->{dsn}, qr/^dbi:SQLite/);
    ok(!$e->connect_info->{user});
  }

lives_ok(
    sub { BPM::Engine->new_with_config(configfile => 'nonexistantfile', connect_info => $dsn) },
    #qr/Specified configfile 'nonexistantfile' does not exist/,
    'Invalid config file ignored'
    );
}

ok($e = BPM::Engine->new_with_config(
    configfile => './t/etc/engine.yaml',
    logger => BPM::Engine::Logger->new(),
    ));
isa_ok($e, 'BPM::Engine');
is($e->connect_info->{user}, 'testuser');

# new_with_traits

{
package Foo;
use Moose::Role;

has 'do_stuff' => ( is => 'ro' );

before 'start_process_instance' => sub {
    my $self = shift;
    my $pi = shift;
    #warn "STARTING PROCESS INSTANCE " . $pi->process->process_uid;
    };

no Moose::Role;
}

ok($e = BPM::Engine->with_traits(qw/+Foo/)->new(
    #connect_info => { dsn => $dsn },
    schema => schema(),
    #callback     => $callback,
    log_dispatch_conf => {
        class     => 'Log::Dispatch::Screen',
        min_level => 'critical',
        stderr    => 1,
        format    => '[%p] %m at %F line %L%n',
        },
    ));
ok($e->can('do_stuff'));
isa_ok($e, 'BPM::Engine');
isa_ok($e->schema, 'BPM::Engine::Store');
isa_ok($e->schema->resultset('BPM::Engine::Store::Result::Package')->search, 'BPM::Engine::Store::ResultSet::Package');
# test hack: deploy memory db
#$e->schema->deploy if($dsn =~ /:memory:/);
ok(!$e->schema->resultset('BPM::Engine::Store::Result::Package')->search->all);

#- traits + config file

ok($e = BPM::Engine
    ->with_traits(qw/+Foo/)
    ->new_with_config(configfile => './t/etc/engine.yaml'));

isa_ok($e, 'BPM::Engine');
ok($e->can('do_stuff'));


#- attributes and roles

$e = new_ok('BPM::Engine' => [ connect_info => $dsn ]);
meta_ok($e);

foreach(qw/logger log_dispatch_conf callback schema connect_info/) {
    has_attribute_ok($e, $_);
    }

foreach(qw/
    MooseX::SimpleConfig
    BPM::Engine::Role::WithLogger
    BPM::Engine::Role::WithCallback
    BPM::Engine::Role::WithPersistence
    BPM::Engine::Handler::ProcessDefinitionHandler
    BPM::Engine::Handler::ProcessInstanceHandler
    BPM::Engine::Handler::ActivityInstanceHandler
    BPM::Engine::Role::EngineAPI
    /) {
    does_ok($e, $_);
    }

with_immutable { ok(1) } qw/BPM::Engine/;

can_ok($e, qw/schema log debug info runner/ );

#-- Engine construction
#----------------------------------------------------------------------------


no warnings 'redefine';
#sub diag {}
use warnings;

my $callback = sub {
        my($runner, $entity, $event, $node, $instance) = @_;
        #diag('callback...');
        my %dispatcher = (
            process => {
                start => sub {
                    my ($node, $instance) = @_;
                    diag 'Starting process ' . $node->process_uid;
                    isa_ok($node, 'BPM::Engine::Store::Result::Process');
                    isa_ok($instance, 'BPM::Engine::Store::Result::ProcessInstance');
                    return 1;
                    },
                complete => sub {
                    my ($node, $instance) = @_;
                    diag 'Completing process' . $node->process_uid;
                    return 1;
                    },
                },
            activity => {
                start   => sub {
                    my ($node, $instance) = @_;
                    diag 'Starting activity ' . $node->activity_uid;
                    isa_ok($node, 'BPM::Engine::Store::Result::Activity');
                    isa_ok($instance, 'BPM::Engine::Store::Result::ActivityInstance');
                    return 1;
                    },
                continue => sub {
                    my ($node, $instance) = @_;
                    diag 'Continuing activity ' . $node->activity_uid;
                    return 1;
                    },
                execute => sub {
                    my ($node, $instance) = @_;
                    diag 'Executing activity ' . $node->activity_uid;
                    return 1;
                    },
                complete => sub {
                    my ($node, $instance) = @_;
                    diag 'Completing activity ' . $node->activity_uid;
                    return 1;
                    },
                },
            task => {
                execute => sub {
                    my ($node, $instance) = @_;
                    diag 'Executing task ' . $node->activity->activity_uid;
                    isa_ok($node, 'BPM::Engine::Store::Result::ActivityTask');
                    isa_ok($instance, 'BPM::Engine::Store::Result::ActivityInstance');
                    return 1;
                    },
                },
            transition => {
                execute => sub {
                    my ($node, $instance) = @_;
                    diag 'Executing transition' . $node->transition_uid;
                    isa_ok($node, 'BPM::Engine::Store::Result::Transition');
                    isa_ok($instance, 'BPM::Engine::Store::Result::ActivityInstance');
                    return 1;
                    },
                },
            );
        die("Unknown callback") unless $dispatcher{$entity}{$event};
        return $dispatcher{$entity}{$event}->($node, $instance);

        #is($entity, 'activity');
        #is($event, 'execute');
        #diag('end callback...');
        };

my ($package, $process) = ();

#-- ProcessDefinition Methods (Handler::ProcessDefinitionHandler)
#----------------------------------------------------------------------------
my $engine = BPM::Engine->new(
    #connect_info => { dsn => $dsn },
    schema => schema(),
    #callback => $callback,
    log_dispatch_conf => {
        class     => 'Log::Dispatch::Screen',
        min_level => 'critical',
        stderr    => 1,
        format    => '[%p] %m at %F line %L%n',
        },);
# test hack: deploy memory db
#$engine->schema->deploy if($dsn =~ /:memory:/);

is($engine->get_packages->count, 0, 'No Packages');
is($engine->get_process_definitions->count, 0, 'No Processes');

#-- create_package

throws_ok( sub { $engine->create_package() }, qr/Validation failed/, 'Validation failed' );

my $str = '';
throws_ok( sub { $engine->create_package(\$str) }, qr/Empty String/, 'Validation failed' );
throws_ok( sub { $engine->create_package(\$str) }, 'BPM::Engine::Exception::Model', 'Validation failed' );
throws_ok( sub { $engine->create_package($str) }, qr/Empty file/, 'Empty String' );
throws_ok( sub { $engine->create_package($str) }, 'BPM::Engine::Exception::Parameter', 'Validation failed' );

my $doc = XML::LibXML->new->parse_string('<root/>');
throws_ok( sub { $engine->create_package($doc) }, qr/XPDLVersion not defined/, 'Validation failed' );
throws_ok( sub { $engine->create_package($doc) }, 'BPM::Engine::Exception::Model', 'Validation failed' );

is($engine->get_packages->count, 0, 'No Packages');

$package = $engine->create_package('./t/var/08-samples.xpdl');
isa_ok($package,'BPM::Engine::Store::Result::Package');
is($package->package_uid, 'samples');

#-- list_packages

is($engine->get_packages->count, 1, 'Package created');
$package = $engine->get_packages->first;
isa_ok($package,'BPM::Engine::Store::Result::Package');

#-- list_process_definitions

is($engine->get_process_definitions->count, 9, 'Processes created');
$process = $engine->get_process_definitions({ process_uid => 'multi-inclusive-split-and-join' })->first;
isa_ok($process, 'BPM::Engine::Store::Result::Process');

#-- get_process_definition

throws_ok( sub { $engine->get_process_definition() },         qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->get_process_definition('string') }, qr/Validation failed/, 'Validation failed' );

$process = $engine->get_process_definition($process->id);
isa_ok($process, 'BPM::Engine::Store::Result::Process');

#-- delete_package

throws_ok( sub { $engine->delete_package() },          qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->delete_package('string') },  qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->delete_package(1) },         qr/Validation failed/, 'Validation failed' );

$engine->delete_package($package->id);
is($engine->get_packages->count, 0, 'Package deleted');
is($engine->get_process_definitions->count, 0, 'Process deleted');

#-- ProcessInstance Methods (Handler::ProcessInstanceHandler)
#----------------------------------------------------------------------------

$package = $engine->create_package('./t/var/08-samples.xpdl');
my @procs = $engine->get_process_definitions({ process_uid => 'unstructured-inclusive-tasks' })->all;
is(@procs, 1);
$process = shift @procs;
isa_ok($process, 'BPM::Engine::Store::Result::Process');

#-- create_process_instance

throws_ok( sub { $engine->create_process_instance() },          qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->create_process_instance('string') },  qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->create_process_instance(987654321) }, qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->create_process_instance('3C2B6B44-E2DB-1014-857D-7D16527AAD97') }, qr/Process 3C2B6B44-E2DB-1014-857D-7D16527AAD97 not found/, 'Process not found' );

ok(my $pi0 = $engine->create_process_instance($process->id));
isa_ok($pi0, 'BPM::Engine::Store::Result::ProcessInstance');

ok(my $pi = $engine->create_process_instance($process, { instance_name => 'my process instance' }));
isa_ok($pi, 'BPM::Engine::Store::Result::ProcessInstance');
is($pi->instance_name, 'my process instance');

#-- list_process_instances

is($engine->get_process_instances->count, 2, 'Two process instances found');
my $first_pi = $engine->get_process_instances->first;
isa_ok($first_pi, 'BPM::Engine::Store::Result::ProcessInstance');
is($pi0->id, $first_pi->id, 'Created process instance found in list');

#-- get_process_instance

throws_ok( sub { $engine->get_process_instance() },          qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->get_process_instance('string') },  qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->get_process_instance(987654321) }, qr/Process instance '987654321' not found/, 'Validation failed' );
throws_ok( sub { $engine->get_process_instance(987654321) }, 'BPM::Engine::Exception::Database', 'Validation failed' );

ok($first_pi = $engine->get_process_instance($first_pi->id));
isa_ok($first_pi, 'BPM::Engine::Store::Result::ProcessInstance');
is($first_pi->workflow_instance->state->name, 'open.not_running.ready');
is($first_pi->state, 'open.not_running.ready');

#-- start_process_instance

throws_ok( sub { $engine->start_process_instance() },          qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->start_process_instance('string') },  qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->start_process_instance(987654321) }, qr/Process instance '987654321' not found/, 'Validation failed' );
throws_ok( sub { $engine->start_process_instance(987654321) }, 'BPM::Engine::Exception::Database', 'Validation failed' );

my $args = { splitA => 'B1', splitB => 'B1' };

is($pi->process->process_uid,'unstructured-inclusive-tasks');

$engine->start_process_instance($pi, $args);

is($pi->workflow_instance->state->name, 'closed.completed');
is($pi->state, 'closed.completed');

#-- terminate_process_instance

#-- abort_process_instance

#-- process_instance_attribute

#-- change_process_instance_state

my $pi1 = $engine->create_process_instance($process);

throws_ok(
    sub { $engine->change_process_instance_state($pi1, 'open.your.eyes') },
    qr/There's no 'open.your.eyes' transition from open.not_running.ready/,
    'Invalid process instance state change failed'
    );

is($pi1->state, 'open.not_running.ready');
my $st = $engine->change_process_instance_state($pi1, 'start');
is($pi1->state, 'open.running');
$engine->change_process_instance_state($pi1, 'terminate');
is($pi1->state, 'closed.cancelled.terminated');

my $pi2 = $engine->create_process_instance($process);
$engine->change_process_instance_state($pi2, 'start');
$engine->change_process_instance_state($pi2, 'abort');
is($pi2->state, 'closed.cancelled.aborted');

my $pi3 = $engine->create_process_instance($process);
$engine->change_process_instance_state($pi3, 'start');
$engine->change_process_instance_state($pi3, 'suspend');
is($pi3->state, 'open.not_running.suspended');
$engine->change_process_instance_state($pi3, 'resume');
is($pi3->state, 'open.running');
$engine->change_process_instance_state($pi3, 'finish');
is($pi3->state, 'closed.completed');

#-- delete_process_instance

is($engine->get_process_instances->count, 5, 'First process instance found');
ok($engine->delete_process_instance($pi));
is($engine->get_process_instances->count, 4, 'First process instance deleted');


#-- Activity Methods (Handler::ActivityInstanceHandler)
#----------------------------------------------------------------------------

$engine->start_process_instance($pi0);

#-- list_activity_instances

#is($engine->get_activity_instances->count, 7);
my $ai = $engine->get_activity_instances->first;
isa_ok($ai, 'BPM::Engine::Store::Result::ActivityInstance');

#-- get_activity_instance

throws_ok( sub { $engine->get_activity_instance() },          qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->get_activity_instance('string') },  qr/Validation failed/, 'Validation failed' );
throws_ok( sub { $engine->get_activity_instance(987654321) }, 'BPM::Engine::Exception::Database', 'Record not found' );

ok($ai = $engine->get_activity_instance($ai->id));
isa_ok($ai, 'BPM::Engine::Store::Result::ActivityInstance');

done_testing;
exit;
#######################

#-- change_activity_instance_state

#ok($engine->change_activity_instance_state($ai->id, 'finish'));

#-- activity_instance_attribute

throws_ok(
    sub { $engine->activity_instance_attribute($ai->id, 'UnknownVar') },
    qr/Attribute named 'UnknownVar' not found/, 'Validation failed'
    );
throws_ok(
    sub { $engine->activity_instance_attribute($ai->id, 'UnknownVar') },
    'BPM::Engine::Exception::Database', 'Validation failed'
    );

ok($ai->add_to_attributes({
    name => 'SomeVar',
    value => 'SomeVal',
    }));

is($engine->activity_instance_attribute($ai->id, 'SomeVar')->value, 'SomeVal');
ok($engine->activity_instance_attribute($ai->id, 'SomeVar', 'OtherValue'));
is($engine->activity_instance_attribute($ai->id, 'SomeVar')->value, 'OtherValue');

undef $engine;

done_testing();
