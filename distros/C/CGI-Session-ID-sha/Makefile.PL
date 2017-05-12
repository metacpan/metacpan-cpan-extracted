use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME => 'CGI::Session::ID::sha',
    VERSION_FROM => 'lib/CGI/Session/ID/sha.pm',
    PREREQ_PM => {
        CGI::Session => 0,
        Digest::SHA => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CGI/Session/ID/sha.pm',
       AUTHOR         => 'Michael De Soto <desoto@cpan.org>') : ()),
);
