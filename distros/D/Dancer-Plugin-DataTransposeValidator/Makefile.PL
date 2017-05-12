use ExtUtils::MakeMaker;

my $PREREQ_PM = {
    'Data::Transpose'  => '0.0020',
    'Moo'              => 0,
    'namespace::clean' => 0,
};

# we are for D1 and D2 and don't want to force users to have both but we
# do want smokers to test on both
if ( $ENV{AUTOMATED_TESTING} || $ENV{TRAVIS} eq 'true' ) {
    $PREREQ_PM->{Dancer} = 0;
    $PREREQ_PM->{Dancer2} = '0.15';
}

WriteMakefile(
    NAME          => 'Dancer::Plugin::DataTransposeValidator',
    AUTHOR        => 'Peter Mottram <peter@sysnix.com>',
    VERSION_FROM  => 'lib/Dancer/Plugin/DataTransposeValidator.pm',
    ABSTRACT      => 'Data::Transpose::Validator plugin for Dancer and Dancer2',
    ( $ExtUtils::MakeMaker::VERSION >= 6.48
        ? ( 'LICENSE' => 'perl' )
        : () ),
    MIN_PERL_VERSION => '5.010000',
    BUILD_REQUIRES   => {
        'Class::Load'           => 0,
        'Email::Valid'          => 0,
        'File::Spec'            => 0,
        'HTTP::Request::Common' => 0,
        'JSON'                  => 0,
        'Plack'                 => '1.0035',
        'Test::Deep'            => 0,
        'Test::Exception'       => 0,
        'Test::More'            => 0,
    },
    PREREQ_PM => $PREREQ_PM,
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer-Plugin-DataTransposeValidator-*' },
    test  => { TESTS => join( ' ', ( glob('t/*.t'), glob('t/*/*.t') ) ) },
    META_MERGE => {
        resources => {
            repository =>
'https://github.com/interchange/Dancer-Plugin-DataTransposeValidator.git',
            bugtracker =>
'https://github.com/interchange/Dancer-Plugin-DataTransposeValidator/issues',
            IRC => 'irc://irc.freenode.net/#interchange',
        },
    },
);
