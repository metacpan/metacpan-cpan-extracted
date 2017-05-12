use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Business::CCCheck',
    ABSTRACT     => 'collection of functions for checking credit card numbers',
    DISTNAME     => 'Business-CCCheck',
    VERSION_FROM => 'lib/Business/CCCheck.pm',
    AUTHOR       => 'Michael Robinton <michael@bizsystems.com>',
    META_MERGE   => {
        resources => {
            bugtracker  => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Business-CCCheck',
            repository => 'https://github.com/neilb/Business-CCCheck',
        },  
    },  
    PREREQ_PM    => {
        'Exporter'   => 0,
        'strict'     => 0,
        'warnings'   => 0,
    },

    ($mm_ver >= 6.52
        ? (CONFIGURE_REQUIRES => {
                'ExtUtils::MakeMaker' => 6.30,
          })
        : ()
    ),

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => {
                'Test::More' => 0.88,
          })
        : ()
    ),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver >= 6.31
        ? (LICENSE => 'gpl_2')
        : ()
    ),

);
