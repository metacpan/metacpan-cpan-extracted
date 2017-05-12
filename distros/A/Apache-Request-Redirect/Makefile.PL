use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::Request::Redirect',
    'VERSION_FROM'	=> 'Redirect.pm', # finds $VERSION
    'PREREQ_PM'		=> {	
												HTTP::Request,
												HTTP::Headers,
												HTTP::Response,
												URI}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Redirect.pod', # retrieve abstract from module
       AUTHOR     => 'Emiliano Bruni <info@ebruni.it>') : ()),
);
