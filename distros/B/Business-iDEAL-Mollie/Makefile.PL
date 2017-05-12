use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Business::iDEAL::Mollie',
    VERSION_FROM   => 'lib/Business/iDEAL/Mollie.pm',
    ABSTRACT_FROM  => 'lib/Business/iDEAL/Mollie.pm', 
    AUTHOR         => 'M. Blom <blom@cpan.org>',
    PREREQ_PM      => {
                      LWP::UserAgent    => 0,
                      XML::Simple       => 0,
    },
);
