use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Enzyme',
    AUTHOR              => 'Johan Lindström <johanl ÄT cpan.org>',
    VERSION_FROM        => 'lib/Catalyst/Enzyme.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Enzyme.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        
        "Catalyst" => 0,
        "Catalyst::Model::CDBI" => 0.10,
        "Catalyst::Plugin::FormValidator" => 0,
        "Catalyst::View::TT::ControllerLocal" => 0,
        "Catalyst::Helper::Model::CDBI" => 0,
        "Catalyst::Plugin::DefaultEnd" => 0,        
        "Data::FormValidator" => 4.02,

        "Class::DBI" => 0.96,
        "Class::DBI::SQLite" => 0.09,
        "Class::DBI::Plugin::Type" => 0.02,
        "Class::DBI::FromForm" => 0.03,
        "Class::DBI::AsForm" => 2.42,
        "Class::DBI::Pager" => 0,
        "DBI::Shell" => 0,
        
        "HTML::Element" => 0,
        "URI" => 0,
        "URI::QueryParam" => 0,
        "Path::Class" => 0,
        "File::Slurp" => 0,
        "List::Util" => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Enzyme-*' },
);
