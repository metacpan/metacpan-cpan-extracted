use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'      => 'Bjorn Ardo (f98ba@efd.lth.se)',
    'NAME'	=> 'Apache::HTMLView',
    'VERSION_FROM' => 'HTMLView.pm', # finds $VERSION
        'PREREQ_PM'   => {
        'Apache'        => '0', 
    }

);
