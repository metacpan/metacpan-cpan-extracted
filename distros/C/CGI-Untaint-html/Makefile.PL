use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'CGI::Untaint::html',
    'VERSION_FROM'	=> 'html.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        CGI::Untaint => 0,
        Test::CGI::Untaint => 0,
        HTML::Sanitizer => 0
    }, # e.g., Module::Name => 1.1
);
