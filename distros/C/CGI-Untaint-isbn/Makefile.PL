use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'CGI::Untaint::isbn',
    'VERSION_FROM'	=> 'isbn.pm', # finds $VERSION
    'PREREQ_PM'		=> {
         'CGI::Untaint'   => 0,
         'Business::ISBN' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'isbn.pm', # retrieve abstract from module
       AUTHOR        => 'Steve Rushe <steve-cpan@deeden.co.uk>') : ()),

);
