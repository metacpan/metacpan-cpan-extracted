# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use 5.008008;
use ExtUtils::MakeMaker;
use lib qw(../lib);
use Cv::Config;

my $cf = new Cv::Config;
my $name = 'BGCodeBookModel';

WriteMakefile(
	NAME => "Cv::$name",
	VERSION_FROM => "lib/Cv/$name.pm",
	ABSTRACT_FROM => "lib/Cv/$name.pm",
	AUTHOR => 'MASUDA Yuta <yuta.cpan@gmail.com>',
	%Cv::Config::MM,
	INC => '-I. -I..',
	XSOPT => '-C++ -hiertype',
);
