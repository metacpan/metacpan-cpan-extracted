use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME              => 'Config::HAProxy',
    VERSION_FROM      => 'lib/Config/HAProxy.pm',
    ABSTRACT_FROM     => 'lib/Config/HAProxy.pm',
    LICENSE           => 'gpl_3',
    AUTHOR            => 'Sergey Poznyakoff <gray@gnu.org>',
    MIN_PERL_VERSION  => 5.010,
    PREREQ_PM         => {
	'Carp'             => 0,
        'Clone'            => 0,
	'Text::Locus'      => 1.00,
        'Text::ParseWords' => 0,
	'File::Basename'   => 0,
	'File::Temp'       => 0
    },
    META_MERGE        => {
	'meta-spec' => { version => 2 },
        resources => {
	    repository => {
		type => 'git',
                url => 'git://git.gnu.org.ua/config-haproxy.git',
		web => 'http://git.gnu.org.ua/cgit/config-haproxy.git/',
	    },
	},
	provides => Module::Metadata->provides(version => '1.4',
					       dir => 'lib')
    }    
);
    
