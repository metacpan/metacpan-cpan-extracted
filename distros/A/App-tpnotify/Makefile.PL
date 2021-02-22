# -*- perl -*-
use strict;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(NAME          => 'App::tpnotify',
	      ABSTRACT      => 'Notifies translationproject.org about new POT file',
	      VERSION_FROM  => 'tpnotify',
	      AUTHOR        => 'Sergey Poznyakoff <gray@gnu.org>',
	      LICENSE       => 'gpl_3',
	      EXE_FILES     => [ 'tpnotify' ],
	      PREREQ_PM     => { 'Getopt::Long' => 2.34,
				 'Pod::Usage'   => 1.51,
				 'Pod::Man'     => 2.25,
                                 'LWP::UserAgent' => 0,
                                 'URI' => 0,
                                 'Unix::Sysexits'  => 0.06,
				 'File::Basename'  => 2.84,
                                 'File::Temp'      => 0.22,
                                 'File::Path'      => 2.08,
                                 'IPC::Open2'      => 1.04,
                                 'Mail::Send'      => 2.09,
			         'Mail::Message'   => 2.115,
				 'Locale::PO'      => 0.27,
                                 'Sys::Hostname'   => 0,
                                 'Data::Dumper'    => 0 },
              MIN_PERL_VERSION => 5.016001,
              META_MERGE => {
		  'meta-spec' => { version => 2 },
		  resources => {
		      repository => {
			  type => 'git',
			  url => 'git://git.gnu.org.ua/tpnotify.git',
			  web => 'http://git.gnu.org.ua/cgit/tpnotify.git/',
		      },
		      bugtracker => {
			  web => 'https://puszcza.gnu.org.ua/bugs/?group=tpnotify',
			  mailto => 'gray+tpnotify@gnu.org.ua'
		      }
	          },
		  provides => {
		      'App::tpnotify' => {
			  file => 'tpnotify',
			  version => '1.03'
		      }
		  }
              }
);

				 
