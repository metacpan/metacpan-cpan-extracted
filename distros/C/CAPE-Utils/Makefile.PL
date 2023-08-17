use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
	NAME             => 'CAPE::Utils',
	AUTHOR           => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
	VERSION_FROM     => 'lib/CAPE/Utils.pm',
	ABSTRACT_FROM    => 'lib/CAPE/Utils.pm',
	LICENSE          => 'artistic_2',
	MIN_PERL_VERSION => '5.006',
	INST_SCRIPT      => 'bin',
	EXE_FILES        => [
		'src_bin/cape_utils',              'src_bin/mojo_cape_submit',
		'src_bin/suricata_extract_submit', 'src_bin/suricata_extract_submit_extend',
		'src_bin/mojo_cape_submit_extend'
	],
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'JSON'                  => '0',
		'Config::Tiny'          => '0',
		'DBI'                   => '0',
		'File::Slurp'           => '0',
		'Config::Tiny'          => '2.28',
		'Text::ANSITable'       => '0.608',
		'YAML'                  => '0',
		'IPC::Cmd'              => '0',
		'File::Spec'            => '0',
		'Net::Subnet'           => '0',
		'Mojolicious::Lite'     => '0',
		'Crypt::Digest::SHA256' => '0',
		'Crypt::Digest::MD5'    => '0',
		'Crypt::Digest::SHA1'   => '0',
		'LWP::UserAgent'        => '0',
		'File::MimeInfo::Magic' => '0',
		'File::Temp'            => '0',
		'File::Copy'            => '0',
		'POSIX'                 => '0',
		'Sys::Syslog'           => '0',
		'HTTP::Request::Common' => '0',
		'Time::Piece'           => '0',
		'File::Find::Rule'      => '0',
		'File::Slurp'           => '0',
		'Gzip::Faster'          => '0',
		'MIME::Base64'          => '0',
		'File::ReadBackwards'   => '0',
		'Proc::PID::File'       => '1.29',
		'Statistics::Lite'      => '0',
	},
	dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean      => { FILES    => 'CAPE-Utils-*' },
	META_MERGE => {
		"meta-spec" => { version => 2 },
		resources   => {
			repository => {
				type => 'git',
				url  => 'git@github.com:LilithSec/CAPE-Utils.git',
				web  => 'https://github.com/LilithSec/CAPE-Utils',
			},
		},
	}
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless ( eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 } ) {
	my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
	@{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$test_requires } = values %$test_requires;
}

unless ( eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 } ) {
	my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
	@{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$build_requires } = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
	unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
	unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
	unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
