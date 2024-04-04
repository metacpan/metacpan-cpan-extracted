use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use File::Spec;

WriteMakefile(
	NAME		=> 'CGI::ACL',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/CGI/ACL.pm',
	ABSTRACT_FROM	=> 'lib/CGI/ACL.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	PL_FILES	=> {},
	TEST_REQUIRES => {
		'CGI::Lingua' => 0.15,
		'Data::Dumper' => 0,
		'English' => 0,
		'Test::Carp' => 0,
		'Test::EOF' => 0,
		'Test::EOL' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'File::Spec' => 0,
		'Test::NoWarnings' => 0,
		'Test::CleanNamespaces' => 0,
		'Test::Distribution' => 0,
		'Test::Kwalitee' => 0,
		# 'Test::Perl::Metrics::Simple' => 0,
		'autodie' => 0,
		'strict' => 0,
		'warnings' => 0,
		'IPC::System::Simple' => 0,
		'WWW::RT::CPAN' => 0
	}, PREREQ_PM => {
		'Carp' => 0,
		'namespace::clean' => 0,
		'Net::CIDR' => 0,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean		=> { FILES => 'CGI-ACL-*' },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/CGI-ACL.git',
				web => 'https://github.com/nigelhorne/CGI-ACL',
				repository => 'https://github.com/nigelhorne/CGI-ACL',
			}, bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-ACL',
				web => 'https://github.com/nigelhorne/CGI-ACL/issues',
				url => 'https://github.com/nigelhorne/CGI-ACL/issues',
				mailto => 'bug-CGI-ACL@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
