use 5.012000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'App::Bitcoin::PaperWallet',
	VERSION_FROM => 'lib/App/Bitcoin/PaperWallet.pm',
	MIN_PERL_VERSION => '5.012000',

	EXE_FILES => [
		'bin/paper-wallet',
	],

	PREREQ_PM => {
		'Bitcoin::Crypto' => '1.000',
		'Text::QRCode' => 0,
		'List::Util' => '1.29',
	},

	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			license => 'https://dev.perl.org/licenses',
			bugtracker => {
				web => 'https://github.com/brtastic/perl-app-bitcoin-paperwallet/issues',
			},
			repository => {
				type => 'git',
				url => 'https://github.com/brtastic/perl-app-bitcoin-paperwallet.git',
				web => 'https://github.com/brtastic/perl-app-bitcoin-paperwallet',
			},
		},
	},

	ABSTRACT_FROM => 'lib/App/Bitcoin/PaperWallet.pm',
	AUTHOR => 'Bartosz Jarzyna <brtastic.dev@gmail.com>',
	LICENSE => 'perl',
);
