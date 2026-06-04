use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::CPANfile;

my $prereqs = Module::CPANfile->load('cpanfile')->prereqs;

WriteMakefile(
    NAME           => 'Catalyst::Plugin::OpenIDConnect',
    VERSION_FROM   => 'lib/Catalyst/Plugin/OpenIDConnect.pm',
    ABSTRACT_FROM  => 'lib/Catalyst/Plugin/OpenIDConnect.pm',
    AUTHOR         => 'Tim F. Rayner <tfrayner@cpan.org>',
    PREREQ_PM          => $prereqs->merged_requirements(['runtime'], ['requires'])->as_string_hash,
    CONFIGURE_REQUIRES => $prereqs->merged_requirements(['configure'], ['requires'])->as_string_hash,
    BUILD_REQUIRES     => $prereqs->merged_requirements(['test', 'build'], ['requires'])->as_string_hash,
    LICENSE        => 'artistic_2',
    META_MERGE     => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/tfrayner/catalyst-plugin-openidconnect.git',
                web  => 'https://github.com/tfrayner/catalyst-plugin-openidconnect',
            },
            bugtracker => {
                web => 'https://github.com/tfrayner/catalyst-plugin-openidconnect/issues',
            },
        },
    },
    PL_FILES       => {},
);
