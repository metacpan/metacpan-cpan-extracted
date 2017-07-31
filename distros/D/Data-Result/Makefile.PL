use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Result',
    VERSION_FROM      => 'lib/Data/Result.pm', # finds $VERSION
    PREREQ_PM         => {
    qw(
      Moo  2.003002
      overload 1.28
      Modern::Perl 1.20170117
      MooX::Types::MooseLike::Base 0.29
      Carp 1.42
      namespace::clean 0.27
      Data::Dumper  2.167
      Test::More    1.302073
    )
    
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/Result.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Shipper <AKALINUX@CPAN.ORG>') : ()),
);
