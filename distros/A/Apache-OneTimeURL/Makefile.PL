require 5.004;
use strict;
use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    'NAME'         => 'Apache::OneTimeURL',
    'VERSION_FROM' => 'lib/Apache/OneTimeURL.pm', # finds $VERSION
    'dist'         => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
    PREREQ_PM      => {
         'Apache'         => 0,
         'Digest::MD5'    => 0,
         'DB_File'        => 0,
         'MLDBM'          => 0,
         'Mail::Send'     => 0
    },

    ($mm_ver >= 6.31
        ? (LICENSE => 'perl')
        : ()
    ),

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                bugtracker  => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Apache-OneTimeURL',
                repository  => {
                    type => 'git',
                    web  => 'https://github.com/neilb/Apache-OneTimeURL',
                    url  => 'git://github.com/neilb/Apache-OneTimeURL.git',
                },
            },
          })
    ),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver >= 6.52
        ? (CONFIGURE_REQUIRES => {
                'ExtUtils::MakeMaker' => 6.30,
          })
        : ()
    ),

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => {
                'Test' => 0,
          })
        : ()
    ),

);
