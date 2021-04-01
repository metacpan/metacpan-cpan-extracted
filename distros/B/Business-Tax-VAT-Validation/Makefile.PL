use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Business::Tax::VAT::Validation',
    'VERSION_FROM'	=> 'lib/Business/Tax/VAT/Validation.pm', # finds $VERSION
    'PREREQ_PM'		=>  {
				HTTP::Request::Common => 1.0,
				LWP::UserAgent	      => 1.0,
				JSON                  => 0,
				perl                  => 5.8.9,
                            }, 
    ABSTRACT_FROM    => 'lib/Business/Tax/VAT/Validation.pm',
    AUTHOR           => 'David Precious <davidp@preshweb.co.uk>',
    LICENSE          => 'GPL_3',
    META_MERGE => {
    resources => {
        repository => 'https://github.com/bigpresh/Business-Tax-VAT-Validation',
        bugtracker => 'https://github.com/bigpresh/Business-Tax-VAT-Validation/issues',
        homepage   => 'https://github.com/bigpresh/Business-Tax-VAT-Validation/', 
    },  
}, 
);
