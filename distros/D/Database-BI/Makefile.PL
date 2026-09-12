use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME			 => 'Database::BI',
	VERSION_FROM	 => 'lib/Database/BI.pm',
	ABSTRACT_FROM => 'lib/Database/BI.pm',
	AUTHOR		   => 'Nigel Horne <njh@nigelhorne.com>',
	LICENSE		  => 'gpl_2',
	MIN_PERL_VERSION => '5.020000',
	EXE_FILES	=> ['script/database-bi'],
	PREREQ_PM => {
		'Carp'		=> 0,
		'CGI::Info'		=> 0,
		'CGI::Lingua'		=> 0,
		'Database::Abstraction'	=> '0.41',
		'DBI'			=> 0,
		'File::Spec'		=> '3.40',
		'File::Temp'		=> '0.22',
		'List::Util'		=> '1.40',
		'Scalar::Util'		=> '1.40',
		'Socket'		=> '2.010',
		'HTML::D3'	=> 0.11,
		'HTML::TableExtract'	=> 0,
		'LWP::UserAgent'		=> 0,
		'LWP::UserAgent::Cached'	=> 0,
		'Mojolicious'	=> '9.49',
		'Mojolicious::Plugin::TemplateToolkit' => 0,
		'Params::Get'	=> 0,
		'Params::Validate::Strict'	=> '0.39',
		'Readonly'		=> 0,
		'Sub::Protected'	=> 0,
	}, TEST_REQUIRES => {
		'DBD::CSV' => 0,
		'Encode' => 0,
		'IPC::System::Simple' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Mockingbird' => 0,
		'Test::Most' => 0,
		'Test::Mojo' => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0,
		'Test::Without::Module' => 0,
		'Text::xSV::Slurp' => 0,
		'XML::Simple' => 0,
	}, dist => $dist,
	clean	=> { FILES => 'Database-BI-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/nigelhorne/Database-BI.git',
				web  => 'https://github.com/nigelhorne/Database-BI',
			},
			bugtracker => {
				web => 'https://github.com/nigelhorne/Database-BI/issues',
			},
		},
	},
);
