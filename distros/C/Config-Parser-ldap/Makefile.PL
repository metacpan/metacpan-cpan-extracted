# -*- perl -*-
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(NAME      =>      'Config::Parser::ldap',
	      ABSTRACT_FROM  => 'lib/Config/Parser/ldap.pm',
	      VERSION_FROM  =>  'lib/Config/Parser/ldap.pm',
	      AUTHOR    =>      'Sergey Poznyakoff <gray@gnu.org>',
	      LICENSE   =>      'gpl_3',
	      MIN_PERL_VERSION => 5.016001,
	      PREREQ_PM         => {
		  'Carp'    => 0,
		  'Config::Parser' => '1.03',
		  'Config::AST' => '1.05'
	      },
	      META_MERGE        => {
		  'meta-spec' => { version => 2 },
		  resources => {
		      repository => {
			  type => 'git',
			  url => 'git://git.gnu.org.ua/config-parser-ldap.git',
			  web => 'http://git.gnu.org.ua/cgit/config-parser-ldap.git/',
		      },
		      bugtracker => {
		          web => 'https://puszcza.gnu.org.ua/bugs/?group=config-parser-ldap',
		          mailto => 'gray+config-parser-ldap@gnu.org.ua'
		      }
		  },
		  provides => Module::Metadata->provides(version => '1.4',
							 dir => 'lib')
	      }
);
