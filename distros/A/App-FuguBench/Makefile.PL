use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'App::FuguBench',
	VERSION          => '0.1.0',
	ABSTRACT         => 'outfit a FuguBSD checkout for a coding agent',
	LICENSE          => 'open_source',
	MIN_PERL_VERSION => '5.034',
	EXE_FILES        => [
		'bin/fugubench'
	],
	PREREQ_PM        => {
		'Fugu' => 0
	},
	PM               => {
		'lib/App/FuguBench.pm' => '$(INST_LIB)/App/FuguBench.pm',
		'lib/App/FuguBench.pod' => '$(INST_LIB)/App/FuguBench.pod',
		'lib/App/FuguBench/Checkout.pm' => '$(INST_LIB)/App/FuguBench/Checkout.pm',
		'lib/App/FuguBench/Checkout.pod' => '$(INST_LIB)/App/FuguBench/Checkout.pod',
		'lib/App/FuguBench/Deps.pm' => '$(INST_LIB)/App/FuguBench/Deps.pm',
		'lib/App/FuguBench/Deps.pod' => '$(INST_LIB)/App/FuguBench/Deps.pod',
		'lib/App/FuguBench/Dist.pm' => '$(INST_LIB)/App/FuguBench/Dist.pm',
		'lib/App/FuguBench/Dist.pod' => '$(INST_LIB)/App/FuguBench/Dist.pod',
		'lib/App/FuguBench/Doctor.pm' => '$(INST_LIB)/App/FuguBench/Doctor.pm',
		'lib/App/FuguBench/Doctor.pod' => '$(INST_LIB)/App/FuguBench/Doctor.pod',
		'lib/App/FuguBench/Fetch.pm' => '$(INST_LIB)/App/FuguBench/Fetch.pm',
		'lib/App/FuguBench/Fetch.pod' => '$(INST_LIB)/App/FuguBench/Fetch.pod',
		'lib/App/FuguBench/Hook.pm' => '$(INST_LIB)/App/FuguBench/Hook.pm',
		'lib/App/FuguBench/Hook.pod' => '$(INST_LIB)/App/FuguBench/Hook.pod',
		'lib/App/FuguBench/Keys.pm' => '$(INST_LIB)/App/FuguBench/Keys.pm',
		'lib/App/FuguBench/Keys.pod' => '$(INST_LIB)/App/FuguBench/Keys.pod',
		'lib/App/FuguBench/Traces.pm' => '$(INST_LIB)/App/FuguBench/Traces.pm',
		'lib/App/FuguBench/Traces.pod' => '$(INST_LIB)/App/FuguBench/Traces.pod',
		'lib/App/FuguBench/Update.pm' => '$(INST_LIB)/App/FuguBench/Update.pm',
		'lib/App/FuguBench/Update.pod' => '$(INST_LIB)/App/FuguBench/Update.pod',
		'lib/App/FuguBench/Version.pm' => '$(INST_LIB)/App/FuguBench/Version.pm',
		'lib/App/FuguBench/Version.pod' => '$(INST_LIB)/App/FuguBench/Version.pod',
		'lib/App/FuguBench/Wiki.pm' => '$(INST_LIB)/App/FuguBench/Wiki.pm',
		'lib/App/FuguBench/Wiki.pod' => '$(INST_LIB)/App/FuguBench/Wiki.pod',
		'lib/App/FuguBench/Worktree.pm' => '$(INST_LIB)/App/FuguBench/Worktree.pm',
		'lib/App/FuguBench/Worktree.pod' => '$(INST_LIB)/App/FuguBench/Worktree.pod'
	},
	test             => { TESTS => 't/fugubench/*.t' },
);
