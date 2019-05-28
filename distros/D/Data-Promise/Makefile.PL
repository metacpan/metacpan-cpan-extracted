use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Promise',
    VERSION_FROM      => 'lib/Data/Promise.pm', # finds $VERSION
    LICENSE=>'perl_5',
    PREREQ_PM         => {
    qw(
      Moo  2.003002
      Modern::Perl 1.20170117
      MooX::Types::MooseLike::Base 0.29
      namespace::clean 0.27
    )
    
    }, # e.g., Module::Name => 1.1
    TEST_REQUIRES=>{
      qw( 
        Test::More    1.302073
      )
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/Promise.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Shipper <AKALINUX@CPAN.ORG>') : ()),
);
