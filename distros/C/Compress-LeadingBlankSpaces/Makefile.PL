use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Compress::LeadingBlankSpaces',
    'AUTHOR'            => 'Slava Bizyayev <slava@cpan.org>',
    'VERSION_FROM'	=> 'LeadingBlankSpaces.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'LeadingBlankSpaces.pm', # retrieve abstract from module
       ) : ()),
);
