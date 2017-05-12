use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Blog::Simple::HTMLOnly',
    'VERSION_FROM'	=> 'HTMLOnly.pm', # finds $VERSION
    PREREQ_PM   => {
	'HTML::TokeParser'	=> '0', # or a minimum working version
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'HTMLOnly.pm', # retrieve abstract from module
       AUTHOR     => 'Lee Goddard <lgoddard -at- cpan -dot- org>') : ()),
);
