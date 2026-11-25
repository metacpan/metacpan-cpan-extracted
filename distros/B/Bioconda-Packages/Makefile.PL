use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Bioconda::Packages',
    ABSTRACT         => 'Query a bundled snapshot of Bioconda package metadata',
    AUTHOR           => 'Andrea Telatin <andrea.telatin@quadram.ac.uk>',
    VERSION_FROM     => 'lib/Bioconda/Packages.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.014',          # core HTTP::Tiny, JSON::PP, IO::Compress

    # Explicit module list plus the bundled gzipped database, installed next to
    # the modules so it is found without File::ShareDir (see
    # Bioconda::Packages::DB::locate_db). Keep this list in sync when adding
    # modules - there are only a handful.
    PM => {
        'lib/Bioconda/Packages.pm'              => '$(INST_LIB)/Bioconda/Packages.pm',
        'lib/Bioconda/Packages/DB.pm'           => '$(INST_LIB)/Bioconda/Packages/DB.pm',
        'lib/Bioconda/Packages/Package.pm'      => '$(INST_LIB)/Bioconda/Packages/Package.pm',
        'lib/Bioconda/Packages/RecipeParser.pm' => '$(INST_LIB)/Bioconda/Packages/RecipeParser.pm',
        'lib/Bioconda/Packages/Updater.pm'      => '$(INST_LIB)/Bioconda/Packages/Updater.pm',
        'share/bioconda-packages.json.gz'
            => '$(INST_LIB)/Bioconda/Packages/bioconda-packages.json.gz',
    },

    EXE_FILES => [ 'bin/bioconda-packages' ],

    PREREQ_PM => {
        'JSON::PP'              => 0,   # core
        'IO::Compress::Gzip'   => 0,   # core
        'IO::Uncompress::Gunzip' => 0, # core
        'HTTP::Tiny'           => 0,   # core (only for maintainer API enrichment)
    },
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.64' },
    TEST_REQUIRES      => { 'Test::More' => 0 },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/telatin/bioconda-packages.git',
                web  => 'https://github.com/telatin/bioconda-packages',
            },
        },
        # The maintainer-only enrichment and build steps are documented but not
        # required to use the module.
        prereqs => {
            develop => {
                recommends => {
                    'File::ShareDir'          => 0,
                    'File::ShareDir::Install'  => 0,
                    # Needed only for `update-db.pl --api` (HTTPS to anaconda.org):
                    'IO::Socket::SSL'          => '1.42',
                    'Net::SSLeay'              => '1.49',
                },
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Bioconda-Packages-*' },
);
