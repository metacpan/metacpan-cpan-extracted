# -*- perl -*-
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(NAME      =>      'Config::Parser',
	      ABSTRACT_FROM  => 'lib/Config/Parser.pm',
	      VERSION_FROM  =>  'lib/Config/Parser.pm',
	      AUTHOR    =>      'Sergey Poznyakoff <gray@gnu.org>',
	      LICENSE   =>      'gpl_3',
	      MIN_PERL_VERSION => 5.016001,
	      PREREQ_PM         => {
		  'Carp'    => 0,
		  'Text::ParseWords' => '3.26',
		  'Data::Dumper' => '2.135_06',
		  'File::Temp'   => '0.22',
                  'Text::Locus'  => '1.01',
                  'Config::AST'  => '1.01'
	      },
	      META_MERGE        => {
		  'meta-spec' => { version => 2 },
		  resources => {
		      repository => {
			  type => 'git',
			  url => 'git://git.gnu.org.ua/config-parser.git',
			  web => 'http://git.gnu.org.ua/cgit/config-parser.git/',
		      },
		  },
		  provides => Module::Metadata->provides(version => '1.4',
							 dir => 'lib')
	      }
);
