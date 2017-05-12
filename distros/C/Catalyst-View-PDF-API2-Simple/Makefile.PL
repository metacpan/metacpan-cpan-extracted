use strict;
use warnings;
use inc::Module::Install;
#use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::View::PDF::API2::Simple',
    AUTHOR              => 'Ferruccio Zamuner <nonsolosoft@diff.org>',
    VERSION_FROM        => 'lib/Catalyst/View/PDF/API2/Simple.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/View/PDF/API2/Simple.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Catalyst::View::TT' => 0,
        'PDF::API2::Simple' => 0,
        'File::chdir' => 0,
        'Template::Plugin::Procedural' => 0,
        'parent' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::File::Contents' => 0,
	'Test::WWW::Mechanize::Catalyst' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-View-PDF-API2-Simple*' },
);
