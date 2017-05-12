use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
BEGIN { require 5.006; }

WriteMakefile(
    'NAME'          => 'Apache::AxKit::Plugin::Upload',
    'AUTHOR'	    => 'Joerg Walter <jwalt@cpan.org>',
    'ABSTRACT'	    => 'upload tracking for AxKit',
    'VERSION_FROM'  => 'lib/Apache/AxKit/Plugin/Upload.pm', # finds $VERSION
    'PREREQ_PM'     => {
    	AxKit => "1.6",
    },
    'dist' => {
        COMPRESS    =>"gzip -9",
        SUFFIX      =>"gz",
        },
);





