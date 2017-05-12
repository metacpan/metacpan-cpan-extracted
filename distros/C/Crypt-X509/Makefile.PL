use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Crypt::X509',
    VERSION_FROM      => 'lib/Crypt/X509.pm',
    PREREQ_PM         => {Convert::ASN1 => 0.19},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Crypt/X509.pm',
       AUTHOR         => 'Mike Jackson, Alexander Jung, Duncan Segrest') : ()),
);
