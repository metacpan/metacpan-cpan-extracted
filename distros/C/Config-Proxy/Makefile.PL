# -*- perl -*-
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(NAME      =>      'Config::Proxy',
	      ABSTRACT_FROM  => 'lib/Config/Proxy.pm',
	      VERSION_FROM  =>  'lib/Config/Proxy.pm',
	      AUTHOR    =>      'Sergey Poznyakoff <gray@gnu.org>',
	      LICENSE   =>      'gpl_3',
	      MIN_PERL_VERSION => 5.016001,
	      PREREQ_PM         => {
		  'Carp'    => 0,
                  'Text::Locus'      => 1.00,
                  'Text::ParseWords' => 0,
                  'File::Basename'   => 0,
                  'File::Temp'       => 0,
                  'IPC::Cmd'         => 0
	      },
	      META_MERGE        => {
		  'meta-spec' => { version => 2 },
	          no_index => {
		      file => [
			  'lib/Config/Proxy/Base.pm',
			  'lib/Config/Proxy/Iterator.pm',
			  'lib/Config/Proxy/Node.pm',
		      ],
		      directory => [
			  'lib/Config/Proxy/Node',
			  'lib/Config/Pound/Node',
			  'lib/Config/Proxy/Impl',
		      ]
		  },
		  resources => {
		      repository => {
			  type => 'git',
			  url => 'git://git.gnu.org.ua/config-pound.git',
			  web => 'http://git.gnu.org.ua/cgit/config-pound.git/',
		      },
		      bugtracker => {
		          web => 'https://puszcza.gnu.org.ua/bugs/?group=config-pound',
		          mailto => 'gray@gnu.org.ua'
		      }
		  },
		  provides => Module::Metadata->provides(version => '1.4',
							 dir => 'lib')
	      }
);

sub MY::postamble {
    'check: test'
}

1;
