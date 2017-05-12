use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Helper::Controller::Scaffold::HTML::Template',
    AUTHOR              => 'Arnaud (Arhuman) Assad <arhuman@gmail.com>',
    VERSION_FROM        => 'lib/Catalyst/Helper/Controller/Scaffold/HTML/Template.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Helper/Controller/Scaffold/HTML/Template.pm',
    PL_FILES            => {},
    PREREQ_PM => {
    'Test::More' => 0,
    'Catalyst' => 5.23,
	'Catalyst::View::HTML::Template' => 0,
    'Catalyst::Plugin::FormValidator' => 0,
	'Class::DBI::AsForm' => 0,
	'Class::DBI::FromForm' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Helper-Controller-Scaffold-HTML-Template-*' },
);
