use strict;

use ExtUtils::MakeMaker;

    WriteMakefile( NAME         => 'DateTime::Event::ICal',
                   VERSION_FROM => 'lib/DateTime/Event/ICal.pm',
                   AUTHOR       => 'Flavio S. Glock <fglock@gmail.com>',
                   ABSTRACT     => 'DateTime rfc2445 recurrences',

                   PREREQ_PM    => { 'DateTime' => 0,
                                     'DateTime::Event::Recurrence' => 0.11,
                                   },
                   META_MERGE   => { 'meta-spec' => { version => 2 },
                                     resources => {
                                        repository => {
                                            type => 'git',
                                            url => 'https://github.com/fglock/DateTime-Event-ICal.git',
                                            web => 'https://github.com/fglock/DateTime-Event-ICal',
                                        },
                                     },
                                   },
                 );

