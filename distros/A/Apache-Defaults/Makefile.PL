use strict;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(NAME         => 'Apache::Defaults',
	      VERSION_FROM => 'lib/Apache/Defaults.pm',
	      AUTHOR       => 'Sergey Poznyakoff <gray@gnu.org>',
	      LICENSE      => 'lgpl_2_1',
	      ABSTRACT_FROM  => 'lib/Apache/Defaults.pm',
	      PREREQ_PM    => {
		  'File::Spec' => '3.40',
		  'IPC::Open3' => '1.13',
		  'Shell::GetEnv' => '0.10',
		  'DateTime::Format::Strptime' => '1.54',
		  'Text::ParseWords' => '3.28'
      	      },
	      TEST_REQUIRES => {
		  'Test' => 0,
		  'File::Temp' => '0.23',
	      },
	      MIN_PERL_VERSION => 5.014002,
	      META_MERGE => {
		  'meta-spec' => { version => 2},
		  resources => {
		      repository => {
			  type => 'git',
			  url => 'git://git.gnu.org.ua/apache-defaults.git',
			  web => 'http://git.gnu.org.ua/cgit/apache-defaults.git'
		      },
		      bugtracker => {
			  web => 'https://puszcza.gnu.org.ua/bugs/?group=apache-defaults',
			  mailto => 'gray+apache-defaults@gnu.org.ua'
		      }		      
		  },
  	          provides => Module::Metadata->provides(version => '1.4',
							 dir => 'lib')
	      }
);
