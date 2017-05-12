use 5.008009;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Convert::Color::HSLuv',
	VERSION_FROM      => 'lib/Convert/Color/HSLuv.pm',
	ABSTRACT          => 'Convert between RGB, CIEXYZ, CIELUV, CIELCh, HSLuv, HPLuv color spaces',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.8.9',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Convert::Color 0/,
	},
	META_MERGE        => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=convert-color-hsluv.git',
		}
	}
);
