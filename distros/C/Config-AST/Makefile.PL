# -*- perl -*-
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(NAME      =>      'Config::AST',
	      ABSTRACT_FROM  => 'lib/Config/AST.pm',
	      VERSION_FROM  =>  'lib/Config/AST.pm',
	      AUTHOR    =>      'Sergey Poznyakoff <gray@gnu.org>',
	      LICENSE   =>      'gpl_3',
	      MIN_PERL_VERSION => 5.016001,
	      PREREQ_PM         => {
		  'Carp'    => 0,
		  'Clone'   => 0,
		  'Data::Dumper' => '2.135_06',
		  'File::Temp'   => '0.22',
		  'File::stat'   => 0,
		  'Scalar::Util' => '1.48',
                  'Text::Locus'  => '1.01'
	      },
	      META_MERGE        => {
		  'meta-spec' => { version => 2 },
		  resources => {
		      repository => {
			  type => 'git',
			  url => 'git://git.gnu.org.ua/config-ast.git',
			  web => 'http://git.gnu.org.ua/cgit/config-ast.git/',
		      },
		  },
		  provides => Module::Metadata->provides(version => '1.4',
							 dir => 'lib')
	      }
);
