use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AnyEvent::SlackBot',
    VERSION_FROM      => 'lib/AnyEvent/SlackBot.pm', # finds $VERSION
    PREREQ_PM         => {
    qw(
      IO::Socket::SSL 1.968
      Moo  2.003002
      overload 1.28
      Modern::Perl 1.20170117
      MooX::Types::MooseLike::Base 0.29
      Carp 1.42
      namespace::clean 0.27
      Data::Dumper  2.167
      Test::More    1.302073
      Data::Result  1.0
      Log::Log4perl 1.49
      Time::HiRes   1.9741
      B             1.68
      Scalar::Util  1.48
      Ref::Util     0.203
      Log::Dispatch::Handle  2.65
      IO::Scalar    2.111
      Exporter      5.72
      Log::LogMethods 1.0
      JSON            2.90
      URI::Escape     3.31
      AnyEvent::HTTP::MultiGet 0
      HTTP::Request::Common 6.13
      LWP::UserAgent  6.26
      HTTP::Request  6.13
      AnyEvent::WebSocket::Client 0.39
    )
    
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AnyEvent/SlackBot.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Shipper <AKALINUX@CPAN.ORG>') : ()),
);
