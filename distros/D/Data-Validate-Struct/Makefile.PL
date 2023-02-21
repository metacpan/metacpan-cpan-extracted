#
# Makefile.PL - build file for Date::Validate::Struct
#
# Copyright (c) 2007-2016 T. v.Dein <tom |AT| cpan.org>.
# All Rights Reserved. Std. disclaimer applies.
# Artistic License, same as perl itself. Have fun.
#

use ExtUtils::MakeMaker;

WriteMakefile(
              NAME         => 'Data::Validate::Struct',
              VERSION_FROM => 'Struct.pm',
              ABSTRACT     => 'Validate recursive hash structures',
              LICENSE      => 'perl',
              AUTHOR       => [
                               'Thomas v.Dein <tom@cpan.org>',
                               'Per Carlson <pelle@cpan.org>',
                              ],
              clean        => { FILES => '*~ */*~' },
              PREREQ_PM    => {
                               'Regexp::Common'     => 0,
                               'Data::Validate'     => '0.06',
                               'Data::Validate::IP' => '0.18',
                              },
              dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
              test         => { TESTS => 't/*.t' },
              'META_MERGE' => {
                               resources => {
                                             repository => 'https://github.com/TLINDEN/Data-Validate-Struct',
                                            },
                              },

             );

