use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# Get XS::Parse::Keyword include path
my $xspk_include = `$^X -MXS::Parse::Keyword::Builder -e 'print XS::Parse::Keyword::Builder->extra_compiler_flags'`;
die "XS::Parse::Keyword::Builder is required to configure this module\n" if $?;

# Extract version from module (avoid hardcoding)
my $version = MM->parse_version('lib/Data/Path/XS.pm');

WriteMakefile(
    NAME             => 'Data::Path::XS',
    VERSION_FROM     => 'lib/Data/Path/XS.pm',
    ABSTRACT_FROM    => 'lib/Data/Path/XS.pm',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.026',
    PREREQ_PM        => {
        'XS::Parse::Keyword' => '0.40',
    },
    TEST_REQUIRES    => {
        'Test::More'      => '0.96',
        'Test::LeakTrace' => '0.14',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'         => '6.64',
        'XS::Parse::Keyword::Builder' => '0.40',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-data-path-xs.git',
                web  => 'https://github.com/vividsnow/perl5-data-path-xs',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-data-path-xs/issues',
            },
        },
        provides => {
            'Data::Path::XS' => {
                file    => 'lib/Data/Path/XS.pm',
                version => $version,
            },
        },
    },
    LIBS     => [''],
    DEFINE   => '',
    INC      => '-I.',
    CCFLAGS  => "$Config{ccflags} $xspk_include",
    OBJECT   => '$(O_FILES)',
    OPTIMIZE => '-O3',
);
