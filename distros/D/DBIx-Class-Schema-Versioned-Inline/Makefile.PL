use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my $MIN_DBIC_VERSION = '0.082820';

WriteMakefile(
    NAME               => 'DBIx::Class::Schema::Versioned::Inline',
    AUTHOR             => q{Peter Mottram (SysPete) <peter@sysnix.com>},
    VERSION_FROM       => 'lib/DBIx/Class/Schema/Versioned/Inline.pm',
    ABSTRACT_FROM      => 'lib/DBIx/Class/Schema/Versioned/Inline.pm',
    LICENSE            => 'perl',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'DBIx::Class'         => $MIN_DBIC_VERSION,
    },
    BUILD_REQUIRES => {
        'Class::Load'                 => 0,
        'DBD::SQLite'                 => '1.40',
        'DBIx::Class::Schema::Loader' => '0.07040',
        'File::Spec'                  => '3.47',
        'Test::Deep'                  => 0,
        'Test::Exception'             => 0,
        'Test::Roo'                   => '1.003',
    },
    CONFIGURE => sub {

        #<<<
        #
        # PREREQ_PM stuff goes here since we need to add DBIC deploy
        # dependencies in the DBIC way so such things as SQLT version
        # deps needed by DBIC are always met correctly
        # https://metacpan.org/pod/distribution/DBIx-Class/lib/DBIx/Class/Optional/Dependencies.pod
        #
        # Also add SQLT dep on version 0 to catch the case of
        # users installing directly from checked out repo who will not have
        # META files yet. This is also needed for travis-ci.
        #
        #>>>

        my $config = {
            PREREQ_PM => {
                'DBIx::Class'        => $MIN_DBIC_VERSION,
                'Safe::Isa'          => 0,
                'Set::Equivalence'   => '0.003',
                'SQL::Translator'    => '0.11021',
                'Try::Tiny'          => '0.18',
                'Types::PerlVersion' => '0.002',
            }
        };

        # now add in the DBIC deps
        eval { require DBIx::Class::Optional::Dependencies };
        return $config if $@;
        my $deploy_deps =
          DBIx::Class::Optional::Dependencies->req_list_for('deploy');
        for ( keys %$deploy_deps ) {
            $config->{PREREQ_PM}->{$_} = $deploy_deps->{$_};
        }
        return $config;
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES => 'DBIx-Class-Schema-Versioned-Inline-*' },
    META_MERGE => {
        resources => {
#<<<
            repository => {
                type => 'git',
                url  => 'git://github.com/Sysnix/dbix-class-schema-versioned-inline.git',
                web  => 'https://github.com/Sysnix/dbix-class-schema-versioned-inline',
            },
            bugtracker => {
                web => 'https://github.com/Sysnix/dbix-class-schema-versioned-inline/issues',
            },
            IRC => 'irc://irc.perl.org/#dbix-class',
#>>>
        },
    },
);
