use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'Authen::Passphrase::Argon2',
	AUTHOR           => q{lnation <thisusedtobeanemail@gmail.com>},
	VERSION_FROM     => 'lib/Authen/Passphrase/Argon2.pm',
	ABSTRACT_FROM    => 'lib/Authen/Passphrase/Argon2.pm',
	LICENSE          => 'artistic_2',
	PL_FILES         => {},
	MIN_PERL_VERSION => '5.006',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	BUILD_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'Authen::Passphrase' => '0.008',
		'Crypt::Argon2' => '0.005',
		'MIME::Base64' => 0,
		'Data::GUID' => '0.049',
		'Carp' => 0,
		'Syntax::Construct' => '1.004',
	},
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/ThisUsedToBeAnEmail/Authen-Passphrase-Argon2.git',
				web  => 'https://github.com/ThisUsedToBeAnEmail/Authen-Passphrase-Argon2',
			},
		},
		x_contributors => [
			'Alexander Hartmaier <abraxxa@cpan.org>',
			'Lars Dɪᴇᴄᴋᴏᴡ 迪拉斯 <daxim@cpan.org>',
			'Wesley Schwengle <waterkip@cpan.org>'
		],
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'Authen-Passphrase-Argon2-*' },
);
