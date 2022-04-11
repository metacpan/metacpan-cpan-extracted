#
# Makefile.PL - build file for Config::General
#
# Copyright (c) 2000-2022 Thomas Linden <tom@daemon.de>.
# All Rights Reserved. Std. disclaimer applies.
# Licensed under the Artistic License 2.0.
#

use ExtUtils::MakeMaker;

WriteMakefile(
              'NAME'         => 'Config::General',
              'VERSION_FROM' => 'General.pm',
              'clean'        => {
                                 FILES                   => 't/*.out t/test.cfg *~ */*~'
                                },
              'PREREQ_PM'    => {
                                 'IO::File'              => 0,
                                 'FileHandle'            => 0,
                                 'File::Spec::Functions' => 0,
                                 'File::Glob'            => 0
                                },
              'META_MERGE' => {
                               resources => {
                                             repository => 'https://github.com/TLINDEN/Config-General'
                                            },
                              },
              ($ExtUtils::MakeMaker::VERSION ge '6.31'?
               ('LICENSE' => 'artistic_2', ) : ()),
             );
