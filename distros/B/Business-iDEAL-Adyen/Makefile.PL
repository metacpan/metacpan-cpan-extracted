use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Business::iDEAL::Adyen',
    VERSION_FROM => 'lib/Business/iDEAL/Adyen.pm', # finds \$VERSION
    AUTHOR       => 'Menno Blom (blom@cpan.org)',
    ABSTRACT     => 'Backend for iDEAL payments through adyen.com',
    PREREQ_PM    => {
		     'Crypt::SSLeay'     => 0,
                     'DateTime'          => 0,
		     'Digest::HMAC_SHA1' => 0,
		     'LWP::UserAgent'    => 5.802,
                     'Test::Simple'      => 0.44,
                     'URI'               => 0,
		     'XML::Simple'       => 0,
                    },
);
