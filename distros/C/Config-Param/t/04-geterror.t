#!perl -T

use Test::More tests => 8;
use Config::Param;
use Storable qw(dclone);

use strict;


my $errors;

# multiple errors in definition (first should trigger)

Config::Param::get
(
	{ silenterr=>1, nofinals=>1, noexit=>1, nofile=>1 }
	,
	[
		 '1234', 'a string', 'a', 'help text for scalar 1'
		,'parm2', 33, 'b', 'help text for scalar 2'
		,'parmA', [ 1, 2, 'free', 'beer' ], 'b', 'help text for array A'
		,'', {'key'=>3, 'donkey'=>'animal'}, 'H', 'help text for hash H'
		,'parmX', 'Y', '',  'helptext for last one (scalar)'
	]
	, ['--not-existing', '--parm2=17', '--parmA-=bla']
	, $errors
);

# one from definition, 3 from cmd line
ok( @{$errors} == 4, 'definiton errors 1');

# another run, still one error in definition

Config::Param::get
(
	{ silenterr=>1, nofinals=>1, noexit=>1, nofile=>1 }
	,
	[
		 'parm1', 'a string', 'a', 'help text for scalar 1'
		,'parm2', 33, 'b', 'help text for scalar 2'
		,'parmA', [ 1, 2, 'free', 'beer' ], 'A', 'help text for array A'
		,'', {'key'=>3, 'donkey'=>'animal'}, 'H', 'help text for hash H'
		,'parmX', 'Y', '',  'helptext for last one (scalar)'
	]
	, ['--not-existing', '--parm2=17', '--parmA-=bla']
	, $errors
);

# one from definition, 3 from cmd line
ok( @{$errors} == 4, 'definiton errors 2');

# another run, sane definition, errors in cmd line
Config::Param::get
(
	{ silenterr=>1, nofinals=>1, noexit=>1, nofile=>1 }
	,
	[
		 'parm1', 'a string', 'a', 'help text for scalar 1'
		,'parm2', 33, 'b', 'help text for scalar 2'
		,'parmA', [ 1, 2, 'free', 'beer' ], 'A', 'help text for array A'
		,'parmH', {'key'=>3, 'donkey'=>'animal'}, 'H', 'help text for hash H'
		,'parmX', 'Y', '',  'helptext for last one (scalar)'
	]
	, ['--not-existing', '--parm2=17', '--parmA-=bla']
	, $errors
);

ok( @{$errors} == 2, 'cmdline errors');

# no errors at all
Config::Param::get
(
	{ nofile=>1 }
	,
	[
		 'parm1', 'a string', 'a', 'help text for scalar 1'
		,'parm2', 33, 'b', 'help text for scalar 2'
		,'parmA', [ 1, 2, 'free', 'beer' ], 'A', 'help text for array A'
		,'parmH', {'key'=>3, 'donkey'=>'animal'}, 'H', 'help text for hash H'
		,'parmX', 'Y', '',  'helptext for last one (scalar)'
	]
	, ['--parm2=17', '--parmA.=bla']
	, $errors
);

ok( @{$errors} == 0, 'no errors');

# error in config file
Config::Param::get
(
	{ silenterr=>1, nofinals=>1, noexit=>1 }
	,
	[
		 'parm1', 'a string', 'a', 'help text for scalar 1'
		,'parm2', 33, 'b', 'help text for scalar 2'
		,'parmA', [ 1, 2, 'free', 'beer' ], 'A', 'help text for array A'
		,'parmH', {'key'=>3, 'donkey'=>'animal'}, 'H', 'help text for hash H'
		,'parmX', 'Y', '',  'helptext for last one (scalar)'
	]
	, ['--parm2=17', '--parmA.=bla']
	, $errors
);

ok( @{$errors} == 1, 'config file error');

# ignored error in config file

Config::Param::get
(
	{ silenterr=>1, nofinals=>1, noexit=>1, ignore_unknown=>1 }
	,
	[
		 'parm1', 'a string', 'a', 'help text for scalar 1'
		,'parm2', 33, 'b', 'help text for scalar 2'
		,'parmA', [ 1, 2, 'free', 'beer' ], 'A', 'help text for array A'
		,'parmH', {'key'=>3, 'donkey'=>'animal'}, 'H', 'help text for hash H'
		,'parmX', 'Y', '',  'helptext for last one (scalar)'
	]
	, ['--parm2=17', '--parmA.=bla']
	, $errors
);

ok( @{$errors} == 0, 'ignored config file error');

# ignored error in config file, but unknown in cmdline

Config::Param::get
(
	{ silenterr=>1, nofinals=>1, noexit=>1, ignore_unknown=>1 }
	,
	[
		 'parm1', 'a string', 'a', 'help text for scalar 1'
		,'parm2', 33, 'b', 'help text for scalar 2'
		,'parmA', [ 1, 2, 'free', 'beer' ], 'A', 'help text for array A'
		,'parmH', {'key'=>3, 'donkey'=>'animal'}, 'H', 'help text for hash H'
		,'parmX', 'Y', '',  'helptext for last one (scalar)'
	]
	, ['--parm2=17', '--parmm.=bla']
	, $errors
);

ok( @{$errors} == 1, 'ignored config file error, but one on command lien');

# also ignoring unknown on command line, nothing bad should happen

Config::Param::get
(
	{ ignore_unknown=>2 }
	,
	[
		 'parm1', 'a string', 'a', 'help text for scalar 1'
		,'parm2', 33, 'b', 'help text for scalar 2'
		,'parmA', [ 1, 2, 'free', 'beer' ], 'A', 'help text for array A'
		,'parmH', {'key'=>3, 'donkey'=>'animal'}, 'H', 'help text for hash H'
		,'parmX', 'Y', '',  'helptext for last one (scalar)'
	]
	, ['--parm2=17', '--parmm.=bla']
	, $errors
);

ok( @{$errors} == 0, 'full-frontal ignorance');
