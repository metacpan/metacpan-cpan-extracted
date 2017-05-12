use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my %config = (
    'NAME'	   => 'AppConfig',
    'VERSION_FROM' => 'lib/AppConfig.pm', # finds $VERSION
    'PMLIBDIRS'    => [ 'lib' ],
    'PREREQ_PM'    => {
        'Test::More'    => 0,
    },
    'MAN3PODS' => {
        # We must explicitly name AppConfig.pm et al as manifyable files.
        # MakeMaker ignores files that match  /(config|setup).*\.pm/i;
        'lib/AppConfig.pm'  => '$(INST_MAN3DIR)/AppConfig.$(MAN3EXT)',
        map {
            ( "lib/AppConfig/${_}.pm",
              "\$(INST_MAN3DIR)/AppConfig::${_}.\$(MAN3EXT)" ) ;
        } qw( Args CGI File Getopt State Sys ),
    },
    'dist' => {
        'COMPRESS' => 'gzip',
        'SUFFIX'   => 'gz',
    },

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository  => {
                    type => 'git',
                    web  => 'https://github.com/neilbowers/AppConfig',
                    url  => 'git://github.com/neilbowers/AppConfig.git',
                },
            },
          })
    ),

    ($mm_ver <= 6.45
        ? ()
        : (TEST_REQUIRES => {
            # optional modules only required for testing
            'Test::Pod' => '1.0',
        })
    ),

    ($mm_ver < 6.48
        ? ()
        : (MIN_PERL_VERSION => '5.8.8',)
    ),

    ($mm_ver <= 6.31
        ? ()
        : (LICENSE => 'perl_5')
    ),

);

## for PPD on win32
if ($] ge '5.005') {
    $config{ AUTHOR   } = 'Andy Wardley <abw@wardley.org>',
    $config{ ABSTRACT } = 'AppConfig is a bundle of Perl5 modules for reading configuration files and parsing command line arguments.';
}

WriteMakefile(%config);
