# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use 5.008008;
use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;

eval "use Cv::Config";
die "Install Cv before installing this module\n" if $@;

my $cf = new Cv::Config;

WriteMakefile(
	NAME => 'Cv::Pango',
	VERSION_FROM => 'lib/Cv/Pango.pm',
	ABSTRACT_FROM => 'lib/Cv/Pango.pm',
	AUTHOR => 'MASUDA Yuta <yuta.cpan@gmail.com>',
	CONFIGURE_REQUIRES => {
		ExtUtils::MakeMaker => 0,
		ExtUtils::PkgConfig => 1.12,
		ExtUtils::ParseXS => 2.22,
	},
	PREREQ_PM => {
		Cv => 0.26,
		ExtUtils::ParseXS => 2.22,
		ExtUtils::PkgConfig => 1.12,
		Pango => 1.223,
	},
	%Cv::Config::MM,
	INC => '-I.',
	XSOPT => '-C++ -hiertype',
	macro => {
		INSTALLPRIVLIB => '$(INSTALLARCHLIB)',
		INSTALLSITELIB => '$(INSTALLSITEARCH)',
		INSTALLVENDORLIB => '$(INSTALLVENDORARCH)',
	},
);
