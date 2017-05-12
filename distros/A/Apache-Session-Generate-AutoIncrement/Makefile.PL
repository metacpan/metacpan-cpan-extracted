use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::Session::Generate::AutoIncrement',
    'VERSION_FROM'	=> 'AutoIncrement.pm', # finds $VERSION
    'PREREQ_PM'		=> { Apache::Session=>1.54, File::CounterFile=>0.12 },
);
