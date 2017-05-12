use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'Apache::SiteControl',
    VERSION_FROM             => 'lib/Apache/SiteControl.pm',
    PREREQ_PM           => { Apache::AuthCookie => 3.04,
                             Apache::Session::File => 1.54,
                             Crypt::CBC => 2.14,
                             Crypt::CAST5 => 0.04,
                           }, # e.g., Module::Name => 1.1
    ABSTRACT            => 'An object-oriented, fine-grained site access control facility',
    AUTHOR              => 'Tony Kay <tkay@uoregon.edu>',
);
