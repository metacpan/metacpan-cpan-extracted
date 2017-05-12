use strict;

use ExtUtils::MakeMaker;

    WriteMakefile( NAME         => 'DateTime::Event::Recurrence',
                   VERSION_FROM => 'lib/DateTime/Event/Recurrence.pm',
                   AUTHOR       => 'Flavio S. Glock <fglock@pucrs.br>',
                   ABSTRACT     => 'DateTime base recurrences',

                   PREREQ_PM    => { 'DateTime' => 0.27,  # local_rd_values
                                     'DateTime::Set' => '0.3600',
                                   },
                   META_MERGE   => { 'meta-spec' => { version => 2 },
                                     resources => {
                                        repository => {
                                            type => 'git',
                                            url => 'https://github.com/fglock/DateTime-Event-Recurrence.git',
                                            web => 'https://github.com/fglock/DateTime-Event-Recurrence',
                                        },
                                     },
                                   },
                 );

