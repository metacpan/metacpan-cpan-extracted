use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Authen::TypeKey::Sign',
    'VERSION_FROM'	=> 'lib/Authen/TypeKey/Sign.pm',
    'PREREQ_PM'		=> { Crypt::DSA => 0, Crypt::DSA::Key => 0,
        Crypt::DSA::Signature => 0, MIME::Base64 => 0, 
        Getopt::Long => 2.33, Pod::Usage => 0, Math::Pari => 0,
        Class::ErrorHandler => 0 }
);
