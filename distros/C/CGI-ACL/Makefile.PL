use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use File::Spec;

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'CGI::ACL',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/CGI/ACL.pm',
	ABSTRACT_FROM	=> 'lib/CGI/ACL.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'gpl_2')
	  : ()),
	PL_FILES	=> {},
	PREREQ_PM => {
		'Carp' => 0,
		'namespace::clean' => 0,
		'Net::CIDR' => 0,
		'Object::Configure' => 0,
		'Params::Get' => 0,
		'Readonly' => 0,
		'Regexp::Common' => 0,
		'Scalar::Util' => 0,
		'Socket' => '2.000',
		'Sub::Protected' => 0,
	}, TEST_REQUIRES => {
		'CGI::Lingua' => 0.15,
		'English' => 0,
		'IPC::System::Simple' => 0,
		'Readonly' => 0,
		'Test::Carp' => 0,
		'Test::CleanNamespaces' => 0,
		'Test::DescribeMe' => 0,
		'Test::Distribution' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::MockObject' => 0,
		'Test::Mockingbird' => 0.12,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::NoWarnings' => 0,
		'Test::Returns' => 0.03,
		'Test::Warn' => 0,
		'Test::Without::Module' => 0,
		'WWW::RT::CPAN' => 0,
	}, dist => $dist,
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
	MIN_PERL_VERSION	=> '5.014'	# Socket::getaddrinfo requires Socket 2.000 (first in Perl 5.14)
);
