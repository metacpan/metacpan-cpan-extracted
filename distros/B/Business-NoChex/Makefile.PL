use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Business::NoChex',
    'VERSION_FROM'	=> 'NoChex.pm', # finds $VERSION
    'PREREQ_PM'		=> {
       	CGI	=> 2.0,
 	Class::MethodMaker => 1.05,
     }, 
);
