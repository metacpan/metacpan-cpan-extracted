use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Chart::Plot::Annotated',
    'VERSION_FROM'	=> 'Annotated.pm', # finds $VERSION
    'PREREQ_PM'		=> {Class::MethodMaker => 1.02,
			    Chart::Plot => 0.10,
			    GD => 1.27,
			   },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Annotated.pm', # retrieve abstract from module
       AUTHOR     => 'Jeremy Kahn <kahn@cpan.org>') : ()),
);
