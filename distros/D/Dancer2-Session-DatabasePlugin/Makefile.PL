use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Dancer2::Session::DatabasePlugin',
    VERSION_FROM      => 'lib/Dancer2/Session/DatabasePlugin.pm', # finds $VERSION
    LICENSE=>'perl_5',
    PREREQ_PM         => {
    qw(
      Moo  2.003002
      Modern::Perl 1.20170117
      MooX::Types::MooseLike::Base 0.29
      Carp 1.38
      namespace::clean 0.27
      Data::Dumper  2.161
      Test::More    1.302073
      Scalar::Util  1.48
      Ref::Util     0.203
      Dancer2::Plugin::Database 2.17
      Dancer2::Core::Role::SessionFactory 0.206000
      Storable  2.62
    )
    
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Dancer2/Session/DatabasePlugin.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Shipper <AKALINUX@CPAN.ORG>') : ()),
);
