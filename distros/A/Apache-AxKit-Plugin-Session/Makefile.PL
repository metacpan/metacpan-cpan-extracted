use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
BEGIN { require 5.006; }
use Apache::AxKit::Language::XSP::SimpleTaglib;
use Apache::Session;

WriteMakefile(
    'NAME'          => 'Apache::AxKit::Plugin::Session',
    'AUTHOR'	    => 'Joerg Walter <jwalt@cpan.org>',
    'ABSTRACT'	    => 'session management for AxKit',
    'VERSION_FROM'  => 'lib/Apache/AxKit/Plugin/Session.pm', # finds $VERSION
    'PREREQ_PM'     => {
    	AxKit => "1.6", # FIXME: not entirely true, but 1.6.1 is not yet released
    	Apache::Session => 0,
    },
    'dist' => {
        COMPRESS    =>"gzip -9",
        SUFFIX      =>"gz",
        },
);





