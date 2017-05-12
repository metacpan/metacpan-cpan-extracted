use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'Catalyst::TraitFor::Model::DBIC::Schema::ResultRoles',
	DISTNAME	=> 'Catalyst-TraitFor-Model-DBIC-Schema-ResultRoles',
	AUTHOR		=> q{Lukas Thiemeier <lukast@cpan.org>},
	VERSION_FROM	=> 'lib/Catalyst/TraitFor/Model/DBIC/Schema/ResultRoles.pm',
	ABSTRACT	=> 'Automatically applying Moose Roles to Result-Classes at BUILD time',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
		? ('LICENSE'=> 'perl')
		: ()),
	PL_FILES            => {},
	PREREQ_PM => {
		'Moose'	=> "1.21",
		'Module::Find' => "0.10",
		'namespace::autoclean' => "0.11",

	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => "6.56",
		'Test::More' => "0.96",
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Catalyst-TraitFor-Model-DBIC-Schema-ResultRoles-*' },
);
