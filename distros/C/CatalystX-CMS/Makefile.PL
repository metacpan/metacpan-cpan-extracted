use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CatalystX::CMS',
    AUTHOR              => 'Peter Karman <karman@cpan.org>',
    VERSION_FROM        => 'lib/CatalystX/CMS.pm',
    ABSTRACT_FROM       => 'lib/CatalystX/CMS.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'CatalystX::CRUD' => '0.32',
        'Catalyst::View::TT' => 0,
        'SVN::Class'         => '0.15',
        'Path::Class::File::Lockable' => 0,
        'XML::Simple' => 0,
        'XML::LibXML' => 0,
        'Template::Plugin::Handy' => 0,
        'Template::Provider::Encoding' => 0,  # quiet View::TT warning
        'DateTime::Format::ISO8601' => 0,
        'Catalyst::Plugin::Static::Simple::ByClass' => 0,
        'Catalyst::Plugin::ConfigLoader' => 0,
        'Catalyst::Action::RenderView'   => 0,
        'MRO::Compat'  => 0,
        'YAML'         => 0, # for tests only
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CatalystX-CMS-*' },
);
