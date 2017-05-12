use strict;
use warnings;
use ExtUtils::MakeMaker;

require 5.008;    # v5.8.0+ needed for safe signals

WriteMakefile(NAME          => 'DBIx::Timeout',
              AUTHOR        => 'Sam Tregar <sam@tregar.com>',
              VERSION_FROM  => 'lib/DBIx/Timeout.pm',
              ABSTRACT_FROM => 'lib/DBIx/Timeout.pm',
              PL_FILES      => {},
              PREREQ_PM     => {
                            'Test::More'       => 0,
                            'DBI'              => '1.49',
                            'Params::Validate' => 0,
                           },
              dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
              clean => {FILES    => 'DBIx-Timeout-*'},);
