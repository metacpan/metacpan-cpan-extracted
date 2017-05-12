use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Business::UPS',
    AUTHOR              => 'Justin Wheeler <upsmodule@datademons.com>',
    VERSION_FROM        => 'lib/Business/UPS.pm',
    ABSTRACT_FROM       => 'lib/Business/UPS.pm',
    PL_FILES            => {},
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'        => 'perl', ) : ()),
    PREREQ_PM => {
        'LWP::UserAgent' => 0,
	'Test::More'     => 0,  # For testing
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Business-UPS-*' },
    META_MERGE  => {
        build_requires => {
            'Test::More' => 0,  # For testing
        },
        resources => {
            license => 'http://dev.perl.org/licenses/',
            homepage => 'http://wiki.github.com/toddr/business-ups',
#            bugtracker => 'http://code.google.com/p/business-ups/issues/list',
            repository => 'http://github.com/toddr/business-ups/tree/master',
#            MailingList => 'http://groups.google.com/group/business-ups',
        },
    },
    );
