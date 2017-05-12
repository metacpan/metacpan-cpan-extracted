use strict;
use warnings;

use ExtUtils::MakeMaker;

# ----------------

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'An almost back-compat fork of CGI::Application',
		) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST CGI-Snapp-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'CGI-Snapp',
	NAME      => 'CGI::Snapp',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		'Capture::Tiny'			=> 0.44,
		'Carp'					=> 1.20,
		'CGI'					=> 4.32,
		'CGI::PSGI'				=> 0.15,
		'CGI::Simple'			=> 1.113,
		'Class::ISA'			=> 0.36,
		'Data::Dumper::Concise'	=> 2.020,
		'File::Spec'			=> 3.40,
		'IO::Pipe'				=> 1.15,
		'lib'					=> 0,
		'Log::Handler'			=> 0.88,
		'Moo'					=> 2.002004,
		'parent'				=> 0.234,
		'Proc::Fork'			=> 0.804,
		'strict'				=> 0,
		'Try::Tiny'				=> 0.27,
		'vars'					=> 0,
		'warnings'				=> 0,
	},
	TEST_REQUIRES =>
	{
		'Test::Deep'	=> 1.120,
		'Test::More'	=> 1.302052,
		'Test::Pod'		=> 1.48,
	},
	VERSION_FROM => 'lib/CGI/Snapp.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'perl';
}

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		'meta-spec' =>
		{
			version => 2,
		},
		resources   =>
		{
			bugtracker	=> 'https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Snapp',
			license		=> 'http://dev.perl.org/licenses/',
			repository	=>
			{
				type	=> 'git',
				url		=> 'https://github.com/ronsavage/CGI-Snapp.git',
				web		=> 'https://github.com/ronsavage/CGI-Snapp',
			},
		},
	};
}

WriteMakefile(%params);
