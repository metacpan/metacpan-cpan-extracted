use ExtUtils::MakeMaker;

use 5.008;

my $version = '0.26';

WriteMakefile
 ( NAME	 	=> 'Any::Daemon::HTTP'
 , VERSION	=> $version
 , PREREQ_PM    =>
   { Any::Daemon      => '0.93'
   , URI              => 0
   , Encode           => 0
   , English          => 0
   , Fcntl            => 0
   , File::Basename   => 0
   , File::Spec       => 0
   , HTTP::Daemon     => '6.03'
   , HTTP::Response   => 0
   , HTTP::Status     => 0
   , IO::Select       => 0
   , IO::Socket       => 0
   , IO::Socket::IP   => 0
   , List::Util       => 0
   , Log::Report      => '1.00'
   , MIME::Types      => 0
   , Net::CIDR        => 0
   , POSIX::1003      => '0.96'
   , Scalar::Util     => 0
   , Socket           => 0
   , Digest::MD5      => '2.53'
   }

 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'preforking http server'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
EXTENDS		= ../AnyDaemon
RAWDIR          = ../public_html/any-daemon-http/raw
DISTDIR         = ../public_html/any-daemon-http/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2013
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/any-daemon/
__POSTAMBLE
