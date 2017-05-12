use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
    (
     'NAME'	    => 'Data::Reconciliation',
     'VERSION_FROM' => 'lib/Data/Reconciliation.pm', # finds $VERSION
     'PREREQ_PM'    => {'Data::Table' => '1.32'},
     'clean'        => {'FILES' => "*.t.log test*.dat *~ */*~ */*/*~ */*/*/*~ */*/*/*/*~"}
     
);
