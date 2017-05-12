use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'    => 'Diane Benz (diane@ahc.umn.edu)',
    'NAME'	=> 'DBIx::OracleLogin',
    'VERSION_FROM' => 'OracleLogin.pm', # finds $VERSION
    'PREREQ_PM'    => {
         'Term::ReadKey'  => '2.0',  
         }
);
