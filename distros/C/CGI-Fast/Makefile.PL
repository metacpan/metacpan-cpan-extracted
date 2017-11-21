use ExtUtils::MakeMaker;
my $mm = $ExtUtils::MakeMaker::VERSION;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    INSTALLDIRS      => ( $] >= 5.012 ? 'site' : 'perl' ),
    NAME             => 'CGI::Fast',
    DISTNAME         => 'CGI-Fast',
    VERSION_FROM     => 'lib/CGI/Fast.pm',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.8.1',
    PREREQ_PM        => {
        'if'          => 0, # core in 5.6.2 and later, for deprecate.pm
        'CGI'         => 4.00,
        'FCGI'        => 0.67,
        'Carp'        => 0, # Carp was first released with perl 6
    },
    TEST_REQUIRES   => {
        'Test::More'      => 0,
        'File::Temp'      => 0,
    },
    test      => { TESTS    => 't/*.t' },
    linkext   => { LINKTYPE => '' }, # no link needed
    dist      => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
        ZIP      => '/usr/bin/zip',
        ZIPFLAGS => '-rl'
    },
    (
        $mm < 6.46
        ? ()
        : ( META_MERGE => {
                requires  => { perl => '5.008001' },
                resources => {
                    license    => 'http://dev.perl.org/licenses/',
                    homepage   => 'https://metacpan.org/module/CGI::Fast',
                    repository => 'https://github.com/leejo/cgi-fast',
                    bugtracker => 'https://github.com/leejo/cgi-fast/issues',
                },
                no_index => { directory => [qw/t/] },
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),
);

