use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile (
  'NAME'           => 'DBIx::DBObj',
  'VERSION_FROM'   => 'lib/DBIx/DBObj.pm', 
  'PREREQ_PM'	   => { 'DBD::mysql'    => '2.1022',
                        'DBI'           => '1.32',
                        'Error'         => '0.15', },


  ( $] >= 5.005 ? ( 
  'AUTHOR'         => 'Matt Knopp <mhat@cpan.org>' 
  ) : () ));
