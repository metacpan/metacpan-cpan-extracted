use strict;
use ExtUtils::MakeMaker 6.46;
require 5.12.4;
WriteMakefile(
    NAME => 'App::HTTP_Proxy_IMP',
    ABSTRACT => 'HTTP(s) proxy with interface to analyze and manipulate data',
    AUTHOR => 'Steffen Ullrich <sullr@cpan.org>',
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            repository  => 'https://github.com/noxxi/p5-app-http_proxy_imp',
            homepage  => 'https://github.com/noxxi/p5-app-http_proxy_imp',
            bugtracker  => 'https://rt.cpan.org/Dist/Display.html?Queue=App-HTTP_Proxy_IMP',
        },
    },
    VERSION_FROM => 'lib/App/HTTP_Proxy_IMP.pm',
    PREREQ_PM => {
	'Net::Inspect' => 0.302,
	'Net::IMP' => 0.617,
	'Net::IMP::HTTP' => 0.51,
	'AnyEvent' => 6.12,
	'IO::Socket::SSL' => 1.92,
    },
    EXE_FILES => [ 'bin/http_proxy_imp' ],
);
