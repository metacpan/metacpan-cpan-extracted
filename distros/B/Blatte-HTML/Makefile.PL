use strict;

use ExtUtils::MakeMaker;

&WriteMakefile(NAME => 'Blatte::HTML',
               VERSION_FROM => 'lib/Blatte/HTML.pm',
               PL_FILES     => {'bin/blatte-html.PL' => 'bin/blatte-html'},
               EXE_FILES    => ['bin/blatte-html'],
               PREREQ_PM    => {'HTML::Entities' => 0,
                                'HTML::Tagset'   => 0,
                                'Blatte'         => 0},
               clean        => {FILES => 'bin/blatte-html'});
