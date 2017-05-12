use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Browse',
    AUTHOR              => 'Roger A Hall <rogerhall@cpan.org>',
    ABSTRACT            => 'Build HTML table from MySQL to display rows with sortable columns, flexible delete links, and multiple column link-outs.',
    VERSION_FROM        => 'lib/CGI/Browse.pm',
    PREREQ_PM           => { 'DBI' => 1.607, 'DBD::mysql' => 2.9004, 'DBIx::MySperqlOO' => 1.0.1, 'Class::Std' => 0.0.8, 'Class::Std::Utils' => 0.0.3 },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Browse-*' },
);
