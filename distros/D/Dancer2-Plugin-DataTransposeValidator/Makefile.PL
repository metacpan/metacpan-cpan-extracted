use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Dancer2::Plugin::DataTransposeValidator',
    AUTHOR        => 'Peter Mottram <peter@sysnix.com>',
    VERSION_FROM  => 'lib/Dancer2/Plugin/DataTransposeValidator.pm',
    ABSTRACT      => 'Data::Transpose::Validator plugin for Dancer2',
    ( $ExtUtils::MakeMaker::VERSION >= 6.48
        ? ( 'LICENSE' => 'perl' )
        : () ),
    MIN_PERL_VERSION => '5.010000',
    BUILD_REQUIRES   => {
        'aliased'               => 0,
        'Email::Valid'          => 0,
        'HTTP::Request::Common' => 0,
        'JSON::MaybeXS'         => 0,
        'Plack'                 => '1.0035',
        'Test::Deep'            => 0,
        'Test::Fatal'           => 0,
        'Test::More'            => 0,
    },
    PREREQ_PM => {
        'Carp'                       => 0,
        'Dancer2::Plugin'            => '0.205000',
        'Dancer2::Core::Types'       => 0,
        'Data::Transpose'            => '0.0020',
        'Data::Transpose::Validator' => 0,
        'Module::Runtime'            => 0,
        'Moo'                        => '2.000000',
        'Path::Tiny'                 => 0,
        'namespace::clean'           => 0,
    },
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-DataTransposeValidator-*' },
    test  => { TESTS => join( ' ', ( glob('t/*.t'), glob('t/*/*.t') ) ) },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/interchange/Dancer2-Plugin-DataTransposeValidator.git',
            bugtracker => 'https://github.com/interchange/Dancer2-Plugin-DataTransposeValidator/issues',
            IRC => 'irc://irc.freenode.net/#interchange',
        },
    },
);
