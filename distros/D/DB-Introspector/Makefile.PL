use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'DB::Introspector',
    'VERSION_FROM' => 'lib/DB/Introspector.pm',
    'PREREQ_PM' => {
        'Config::Properties' => 0.56,
        'Devel::Symdump'     => 1.00,
        'Getopt::Long'       => 1.00,
        'IO::File'           => 1.00,
        'DBI'                => 1.00,
        'Storable'           => 2.00,
        'Test::Unit'         => 0,
        'Test::Unit::TestRunner' => 0
      },
);
