use strict;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(NAME         => 'Apache::Config::Preproc',
	      VERSION_FROM => 'lib/Apache/Config/Preproc.pm',
	      AUTHOR       => 'Sergey Poznyakoff <gray@gnu.org>',
	      LICENSE      => 'lgpl_2_1',
	      ABSTRACT_FROM  => 'lib/Apache/Config/Preproc.pm',
	      PREREQ_PM    => {
		  'Apache::Admin::Config' => '0.95',
		  'File::Spec' => '3.39_02',
		  'Text::ParseWords' => '3.27',
		  'Text::Locus' => '1.03',
		  'File::Spec' => 0,
		  'IPC::Open3' => 0
      	      },
	      TEST_REQUIRES => {
		  'File::Basename' => 0,
		  'File::Path' => 0,
		  'File::Temp' => 0,
		  'Test' => 0,
		  'autodie' => 0
	      },
	      MIN_PERL_VERSION => 5.014002,
	      META_MERGE => {
		  'meta-spec' => { version => 2 },
		  resources => {
		      repository => {
			  type => 'git',
			  url => 'git://git.gnu.org.ua/acpp.git',
			  web => 'http://git.gnu.org.ua/cgit/acpp.git/',
		      },
		      bugtracker => {
			  web => 'https://puszcza.gnu.org.ua/bugs/?group=acpp',
			  mailto => 'gray+acpp@gnu.org.ua'
		      }
		  },
		  provides => Module::Metadata->provides(version => '1.4',
							 dir => 'lib')
	      }
	      
);
	      
