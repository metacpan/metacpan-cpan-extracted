use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'CGI::SpeedUp',
    'VERSION_FROM' => 'SpeedUp.pm', # finds $VERSION
    'PREREQ_PM'     => { 'CGI' => 0,  'File::Spec' => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => '£ukasz Strzelecki <strzelec@rswsystems.pl>') : ()),
);
