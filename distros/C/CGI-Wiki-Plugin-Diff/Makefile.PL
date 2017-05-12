use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'CGI::Wiki::Plugin::Diff',
    'VERSION_FROM'	=> 'lib/CGI/Wiki/Plugin/Diff.pm', # finds $VERSION
    'PREREQ_PM'		=> {VCS::Lite => '0.05',
    			    CGI::Wiki => '0.44',
    			    Module::Optional => 0,
    			    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/CGI/Wiki/Plugin/Diff.pm', # retrieve abstract from module
       AUTHOR     => 'Ivor Williams (IVORW (at) cpan [dot] org)') : ()),
);
