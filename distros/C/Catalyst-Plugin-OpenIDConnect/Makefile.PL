use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::CPANfile;

my $prereqs = Module::CPANfile->load('cpanfile')
  ->prereqs->merged_requirements(['runtime'], ['requires'])
  ->as_string_hash;

WriteMakefile(
    NAME           => 'Catalyst::Plugin::OpenIDConnect',
    VERSION_FROM   => 'lib/Catalyst/Plugin/OpenIDConnect.pm',
    ABSTRACT_FROM  => 'lib/Catalyst/Plugin/OpenIDConnect.pm',
    AUTHOR         => 'Tim F. Rayner <tfrayner@cpan.org>',
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
