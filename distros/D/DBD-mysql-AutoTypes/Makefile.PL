use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'DBD::mysql::AutoTypes',
    'VERSION_FROM'	=> 'lib/DBD/mysql/AutoTypes.pm',
    'PREREQ_PM'		=> {
      'DBI' => 0,
      'DBD::mysql' => 2.9002,
      'Regexp::Common' => 0,
    },
    PMLIBDIRS => [ 'lib' ],
);

__END__
