use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'App::FuguWeb',
	VERSION          => '0.1.1',
	ABSTRACT         => 'build a documentation website for a Perl project',
	LICENSE          => 'open_source',
	MIN_PERL_VERSION => '5.036',
	EXE_FILES        => [
		'bin/fuguweb'
	],
	PREREQ_PM        => {

	},
	PM               => {
		'lib/App/FuguWeb.pm' => '$(INST_LIB)/App/FuguWeb.pm',
		'lib/App/FuguWeb.pod' => '$(INST_LIB)/App/FuguWeb.pod',
		'lib/App/FuguWeb/CLI.pm' => '$(INST_LIB)/App/FuguWeb/CLI.pm',
		'lib/App/FuguWeb/CLI.pod' => '$(INST_LIB)/App/FuguWeb/CLI.pod',
		'lib/App/FuguWeb/Check.pm' => '$(INST_LIB)/App/FuguWeb/Check.pm',
		'lib/App/FuguWeb/Check.pod' => '$(INST_LIB)/App/FuguWeb/Check.pod',
		'lib/App/FuguWeb/Config.pm' => '$(INST_LIB)/App/FuguWeb/Config.pm',
		'lib/App/FuguWeb/Config.pod' => '$(INST_LIB)/App/FuguWeb/Config.pod',
		'lib/App/FuguWeb/Index.pm' => '$(INST_LIB)/App/FuguWeb/Index.pm',
		'lib/App/FuguWeb/Index.pod' => '$(INST_LIB)/App/FuguWeb/Index.pod',
		'lib/App/FuguWeb/Manual.pm' => '$(INST_LIB)/App/FuguWeb/Manual.pm',
		'lib/App/FuguWeb/Manual.pod' => '$(INST_LIB)/App/FuguWeb/Manual.pod',
		'lib/App/FuguWeb/Page.pm' => '$(INST_LIB)/App/FuguWeb/Page.pm',
		'lib/App/FuguWeb/Page.pod' => '$(INST_LIB)/App/FuguWeb/Page.pod',
		'lib/App/FuguWeb/Render.pm' => '$(INST_LIB)/App/FuguWeb/Render.pm',
		'lib/App/FuguWeb/Render.pod' => '$(INST_LIB)/App/FuguWeb/Render.pod',
		'lib/App/FuguWeb/Site.pm' => '$(INST_LIB)/App/FuguWeb/Site.pm',
		'lib/App/FuguWeb/Site.pod' => '$(INST_LIB)/App/FuguWeb/Site.pod',
		'share/fuguweb/style.css' => '$(INST_LIB)/auto/share/dist/App-FuguWeb/fuguweb/style.css'
	},
	test             => { TESTS => 't/fuguweb/*.t' },
);
