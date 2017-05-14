use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Application::Muto',
    AUTHOR              => q{Uriel Lizama <uriel@baboonsoftware.com>},
    VERSION_FROM        => 'lib/CGI/Application/Muto.pm',
    ABSTRACT_FROM       => 'lib/CGI/Application/Muto.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'CGI::Application' => 4,
        'Test::More' => 0,
        'CGI::Application::Plugin::DBH' => 0,
        'CGI::Application::Plugin::ConfigAuto' => 0,
        'CGI::Application::Plugin::Redirect' => 0,
        'CGI::Application::Plugin::LogDispatch' => 0,
        'CGI::Application::Plugin::Session' => 0,
        'Class::Inspector' => 0,
        'Data::Dumper' => 0,
        'Module::Load' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Application-Muto-*' },
);
