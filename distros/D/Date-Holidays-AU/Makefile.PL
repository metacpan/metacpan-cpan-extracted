#! /usr/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Date::Holidays::AU',
    VERSION_FROM     => 'lib/Date/Holidays/AU.pm',
    MIN_PERL_VERSION => '5.006',
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Time::Local'  => 1.28,
        'Date::Easter' => 0,
        'Carp'         => 0,
    },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Date/Holidays/AU.pm',    # retrieve abstract from module
            META_MERGE => {
                resources => {
                    license    => 'http://dev.perl.org/licenses/',
                    repository => {
                        type => 'git',
                        url  =>
                          'https://github.com/david-dick/date-holidays-au.git',
                        web => 'https://github.com/david-dick/date-holidays-au',
                    },
                    bugtracker => {
                        web =>
'https://github.com/david-dick/date-holidays-au/issues',
                    }
                }
            },
            AUTHOR => 'David Dick <ddick@cpan.org>'
          )
        : ()
    ),
    (
        $ExtUtils::MakeMaker::VERSION ge '6.30_00'
        ?    # shamelessly copied this from Template Toolkit
          ( LICENSE => 'perl' )
        : ()
    ),
);
