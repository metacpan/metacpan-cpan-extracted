use strict;
use warnings;
use ExtUtils::MakeMaker;

# eval q{
#     use File::ShareDir::Install 0.07;
#     delete_share '.'; # delete it all first
#     install_share 'share'; # install the current version second
#     *MY::postamble = \&File::ShareDir::Install::postamble;
# };
# warn "-- share/ will not be installed --\n\t$@\n-- end sharedir error --\n" if $@;

WriteMakefile(
    NAME          => 'Dancer2::Plugin::Locale',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Dancer2/Plugin/Locale.pm',
    ABSTRACT_FROM => 'lib/Dancer2/Plugin/Locale.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'              => 0,
        'Plack::Test'             => 0,
        'HTTP::Request::Common'   => 0,
        'Dancer2::Plugin'         => 0,
        'Locale::Maketext::Utils' => 0,
        'Locales'                 => 0.33,
        'File::Spec'              => 0,
        'File::Path::Tiny'        => 0,
        'Template'                => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Dancer2-Plugin-Locale-*' },
);
