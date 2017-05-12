use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::DBI::Plugin::FilterOnClick',
    AUTHOR              => 'Aaron Johnson <aaronjjohnson@gmail.com>',
    VERSION_FROM        => 'lib/Class/DBI/Plugin/FilterOnClick.pm',
    ABSTRACT_FROM       => 'lib/Class/DBI/Plugin/FilterOnClick.pm',
    PL_FILES            => {},
    PREREQ_PM => {
                            'Test::More'                             => 0,
                            'Class::DBI::Pager'                      => undef,
                            'Class::DBI::AsForm'                     => .05,
                            'Class::DBI'                             => .94,
                            'HTML::Table'                            => ">2",
                            'Class::DBI::AbstractSearch'             => .04,
                            'Class::DBI::Plugin'                     => .03,
                            'Class::DBI::Plugin::RetrieveAll'        => 1,
                            'Class::DBI::Plugin::Pager'              => ">.4",
                            'Class::DBI::Plugin::DeepAbstractSearch' => undef,
                            'Class::DBI::Plugin::AbstractCount'      => ">.01",
                            'Tie::Hash::Indexed'                     => ">.02",
                            'HTML::Strip'                            => ">1.00",
                            'HTML::FillInForm'                       => ">1",
                            'CGI::FormBuilder'                       => ">3",
                            'Config::Magic'                          => 0,
                            'URI::Escape'                            => 1
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-DBI-Plugin-FilterOnClick-*' },
);
