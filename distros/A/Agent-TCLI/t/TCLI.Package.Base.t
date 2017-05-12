#!/usr/bin/env perl
# $Id: TCLI.Package.Base.t 57 2007-04-30 11:07:22Z hacker $

use Test::More tests => 68;
use lib 'blib/lib';
use POE;

# TASK Test suite is not complete. Need testing for catching errors.

use_ok('Agent::TCLI::Package::Base');
use_ok('Agent::TCLI::Command');
use_ok('Agent::TCLI::Parameter');

my %cmd1 = (
	        'name'		=> 'cmd1',
	        'contexts'	=> {'/' => 'cmd1'},
    	    'help' 		=> 'cmd1 help',
        	'usage'		=> 'cmd1 usage',
        	'topic'		=> 'test',
        	'call_style'=> 'session',
        	'command'	=> 'test1',
	        'handler'	=> 'cmd1',
);
my %cmd2 = (
	        'name'		=> 'cmd2',
	        'contexts'	=> {'/' => 'cmd2'},
    	    'help' 		=> 'cmd2 help',
        	'usage'		=> 'cmd2 usage',
        	'topic'		=> 'test',
        	'call_style'=> 'session',
        	'command'	=> 'test1',
	        'handler'	=> 'cmd2',
);

my $cmd1 = Agent::TCLI::Command->new(%cmd1);

my $test1 = Agent::TCLI::Package::Base->new({
	'name'		=> 'test1',
});

# Test Load Parameters

ok(!$test1->can('int1'),"parameter attribute not created yet");

$test1->LoadYaml(<<'...');
---
Agent::TCLI::Parameter:
  name: int1
  default: 1
  help: integer one
  constraints:
    - INT
  manual: This is the manual text.
  type: Param
  class: numeric
...

is($test1->parameters->{'int1'}->name,'int1',"single parameter loaded ok");
ok($test1->can('int1'),"parameter attribute created ok");
is($test1->meta->get_methods->{'int1'}{'type'},'numeric', "parameter :Type set ok");
is($test1->int1,1,"default set OK");

$test1->LoadYaml(<<'...');
---
Agent::TCLI::Parameter:
  name: scalar1
  default: some text
  help: scalar one
  constraints:
    - ASCII
  manual: This is the manual text.
  type: Param
...

is($test1->parameters->{'scalar1'}->name,'scalar1',"single parameter loaded ok");
ok($test1->can('scalar1'),"parameter attribute created ok");
is($test1->scalar1,'some text', "default set OK");

$test1->LoadYaml(<<'...');
---
Agent::TCLI::Parameter:
  name: int2
  constraints:
    - INT
  help: integer two
  manual: This is the manual text.
  class: numeric
---
Agent::TCLI::Parameter:
  name: int3
  constraints:
    - INT
  help: integer three
  manual: This is the manual text.
  type: Param
  class: numeric
---
Agent::TCLI::Parameter:
  name: int4
  constraints:
    - INT
  help: integer four
  type: Param
  manual: >
   This is some longer manual text that is supposed to be parsed by
   Yaml in this format. It is unclear from the YAML.pm pod how the indenting is
   supposed to be done on this type of text. Also, any use of non
   alpha-numeric charaters is not described.
  class: numeric
---
Agent::TCLI::Command:
  call_style: session
  command: tcli-pf
  contexts:
    meganat: show
    noresets: show
    test1:
      '*U': show
      test1.1:
        test1.1.1: show
        test1.1.2: show
        test1.1.3: show
      test1.2:
        '*U': show
      test1.3:
        '*U': show
  handler: show
  help: shows things that need showing
  name: show
  topic: attack prep
  usage: '<context> show <something>'
---
Agent::TCLI::Command:
  call_style: session
  command: test1
  contexts:
    '/': cmd1
  handler: cmd1
  help: cmd1 help
  name: cmd1
  parameters:
    int1:
    int2:
  topic: test
  usage: cmd1 usage
---
Agent::TCLI::Command:
  call_style: state
  command: test2
  contexts:
    '/': cmd2
  handler: cmd2
  help: cmd2 help
  name: cmd2
  parameters:
    int1:
    int2:
    int3:
    int4:
  topic: test
  usage: cmd2 usage
...
is($test1->parameters->{'int2'}->name,'int2',"array of parameters loaded ok");
is($test1->parameters->{'int3'}->name,'int3',"array of parameters loaded ok");
is($test1->parameters->{'int4'}->name,'int4',"array of parameters loaded ok");
is($test1->commands->{'show'}->name,'show',"command show loaded ok");

is(ref($test1),'Agent::TCLI::Package::Base','new test1 object');

my $test2 = Agent::TCLI::Package::Base->new();
is(ref($test2),'Agent::TCLI::Package::Base', 'new test2 object' );

# Test name accessor-mutator methods
is($test1->name(),'test1', '$test1->name accessor from init args');
# for init 'name'		=> 'test1',
ok($test2->name('test2'),'$test2->name mutator ');
is($test2->name,'test2', '$test2->name accessor from mutator');

# Test verbose get-set methods
is($test1->verbose,0, '$test1->verbose get from init args');
# for init 'verbose'		=> '0',
ok($test2->verbose(1),'$test2->verbose set ');
is($test2->verbose,1, '$test2->verbose get from set');

is($test1->Verbose("ok"),undef,'$test1->Verbose returns undef');
like($test2->Verbose("ok"),qr(ok),'$test1->Verbose returns ok');

is($test2->verbose(0),0,'$test2->verbose set 0');

$c1 = $test1->commands;
# Test commands accessor-mutator methods
is(ref($c1),'HASH', '$test1->commands accessor from init args');

is(ref($c1->{'cmd1'}),'Agent::TCLI::Command',' $test1->commands{cmd1}  isa Agent::TCLI::Command');
is(ref($c1->{'cmd2'}),'Agent::TCLI::Command',' $test1->commands{cmd2}  isa Agent::TCLI::Command');

is($c1->{'cmd1'}->name,'cmd1','$test1 commands->{cmd1}->name');
is($c1->{'cmd2'}->name,'cmd2','$test1 commands->{cmd2}->name');

is($c1->{'cmd1'}->parameters->{'int1'}->name,'int1','$test1 commands->{cmd1}->parameters->{int1}->name');
is($c1->{'cmd1'}->parameters->{'int2'}->name,'int2','$test1 commands->{cmd1}->parameters->{int2}->name');

is($c1->{'cmd2'}->parameters->{'int1'}->name,'int1','$test1 commands->{cmd2}->parameters->{int1}->name');
is($c1->{'cmd2'}->parameters->{'int2'}->name,'int2','$test1 commands->{cmd2}->parameters->{int2}->name');
is($c1->{'cmd2'}->parameters->{'int3'}->name,'int3','$test1 commands->{cmd3}->parameters->{int3}->name');
is($c1->{'cmd2'}->parameters->{'int4'}->name,'int4','$test1 commands->{cmd2}->parameters->{int4}->name');

$test1->LoadXMLFile();

is($test1->parameters->{'int5'}->name,'int5',"array of parameters loaded ok");
is($test1->parameters->{'int6'}->name,'int6',"array of parameters loaded ok");
is($test1->parameters->{'int7'}->name,'int7',"array of parameters loaded ok");
is($test1->commands->{'show'}->name,'show',"command show loaded ok");

$c1 = $test1->commands;
# Test commands accessor-mutator methods
is(ref($c1),'HASH', '$test1->commands accessor from init args');

is(ref($c1->{'cmd4'}),'Agent::TCLI::Command',' $test1->commands{cmd4}  isa Agent::TCLI::Command');
is(ref($c1->{'cmd5'}),'Agent::TCLI::Command',' $test1->commands{cmd5}  isa Agent::TCLI::Command');

is($c1->{'cmd4'}->name,'cmd4','$test1 commands->{cmd4}->name');
is($c1->{'cmd5'}->name,'cmd5','$test1 commands->{cmd5}->name');

is($c1->{'cmd4'}->parameters->{'int5'}->name,'int5','$test1 commands->{cmd4}->parameters->{int5}->name');
is($c1->{'cmd4'}->parameters->{'int6'}->name,'int6','$test1 commands->{cmd4}->parameters->{int6}->name');

is($c1->{'cmd5'}->parameters->{'int1'}->name,'int1','$test1 commands->{cmd5}->parameters->{int1}->name');
is($c1->{'cmd5'}->parameters->{'int5'}->name,'int5','$test1 commands->{cmd5}->parameters->{int5}->name');
is($c1->{'cmd5'}->parameters->{'int6'}->name,'int6','$test1 commands->{cmd5}->parameters->{int6}->name');
is($c1->{'cmd5'}->parameters->{'int7'}->name,'int7','$test1 commands->{cmd5}->parameters->{int7}->name');

my @pass_tests = (
	['NotNumeric','a',,'Parameter is not a number'],
	['NotPosInt','a',,'Parameter is not a number'],
	['NotPosInt','3.14',,'Parameter is not an integer'],
	['NotPosInt','-42',,'Parameter is not positive'],
	['NotPosInt','-42','Answer','Answer is not positive'],
	['NotPosInt','a','Answer','Answer is not a number'],
);
my $method;
foreach my $test (@pass_tests)
{
	$method = $test->[0];
	like($test1->$method($test->[1], $test->[2]), qr($test->[3]),
		'$test1->'.$test->[0]."(".$test->[1].", ".$test->[2].") ".$test->[3]
		);
}

my @fail_tests = (
	['NotNumeric','1'],
	['NotNumeric','3.14'],
	['NotNumeric','-42'],
	['NotPosInt','1'],
	['NotScalar','yes'],
	['NotRegex',qr(yes)],
);

foreach my $test (@fail_tests)
{
	$method = $test->[0];
	ok( !$test1->$method($test->[1]), '$test1->'.$test->[0]."(".$test->[1].") fails"
		);
}

ok($test1->set_a_numeric(1),"Setting a numeric through automethod");
is($test1->get_a_numeric,1,"Get a numeric after automethod");
is($test1->increment_a_numeric, 2 , "increment a numeric ");
is($test1->increment_a_numeric(2), 4, "increment a numeric with value 2 from 2 ");



$poe_kernel->run;
