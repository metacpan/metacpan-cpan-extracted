use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'CGI::Session::Serialize::Base64',
    'VERSION_FROM'	=> 'Base64.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'CGI::Session' => 3.95 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Base64.pm', # retrieve abstract from module
       AUTHOR     => 'Matthew Studley <mjfs@cpan.org>') : ()),

);
