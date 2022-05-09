# -*- cperl -*-
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(NAME             => 'App::Regather',
              ABSTRACT         => 'regather - LDAP syncrepl consumer script to perform actions desired on syncrepl event',
              VERSION_FROM     => 'lib/App/Regather.pm',
	      EXE_FILES        => [ 'regather' ],
              AUTHOR           => 'Zeus Panchenko <zeus@gnu.org.ua>',
              LICENSE          => 'gpl_3',
              MIN_PERL_VERSION => 5.016001,
              PREREQ_PM        =>
	      {
	       'Config::AST'          => '1.05',
	       'Config::Parser'       => '1.04',
	       'Config::Parser::ldap' => '1.00',
	       'Data::Printer'        => '0.38',
	       'File::Temp'           => '0.22',
	       'Mail::Send'           => '0.80',
	       'Net::DNS'             => '1.15',
	       'Net::LDAP'            => '0.65',
	       'Sys::Syslog'          => '0.29',
	       'Template'             => '2.29',
	       'Text::Locus'          => '1.01',
	      },
              META_MERGE      =>
	      {
	       'meta-spec' => { version => 2 },
	       resources   =>
	       {
		repository =>
		{
		 type => 'git',
		 url  => 'ssh://git@github.com:z-eos/regather.git',
		 web  => 'https://github.com/z-eos/regather.git',
		},
	       },
	      }
	     );
