use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Business::UPS',
    AUTHOR              => 'Justin Wheeler <upsmodule@datademons.com>',
    VERSION_FROM        => 'lib/Business/UPS.pm',
    ABSTRACT_FROM       => 'lib/Business/UPS.pm',
    MIN_PERL_VERSION    => '5.014',
    PL_FILES            => {},
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'        => 'perl', ) : ()),
    PREREQ_PM => {
        'LWP::UserAgent' => 0,
        'JSON::PP'       => 0,
    },
    TEST_REQUIRES => {
        'Test::More'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Business-UPS-*' },
    META_MERGE  => {
        'meta-spec' => { version => 2 },
        resources => {
            license    => ['http://dev.perl.org/licenses/'],
            bugtracker => { web => 'https://github.com/cpan-authors/Business-UPS/issues' },
            repository => {
                type => 'git',
                url  => 'https://github.com/cpan-authors/Business-UPS.git',
                web  => 'https://github.com/cpan-authors/Business-UPS',
            },
        },
        provides => {
            'Business::UPS' => {
                file    => 'lib/Business/UPS.pm',
                version => MM->parse_version('lib/Business/UPS.pm'),
            },
        },
    },
    );
