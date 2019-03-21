use ExtUtils::MakeMaker;

use 5.010;

my $version = '0.28';

WriteMakefile
 ( NAME	 	=> 'Any::Daemon::HTTP'
 , VERSION	=> $version

 , PREREQ_PM    =>
   { Any::Daemon      => 0.96
   , URI              => 0
   , Encode           => 0
   , English          => 0
   , Fcntl            => 0
   , File::Basename   => 0
   , File::Spec       => 0
   , HTTP::Daemon     => 6.03
   , HTTP::Response   => 0
   , HTTP::Status     => 0
   , IO::Select       => 0
   , IO::Socket       => 0
   , IO::Socket::IP   => 0
   , List::Util       => 0
   , LWP::UserAgent   => 6.00
   , Log::Report      => 1.00
   , MIME::Types      => 0
   , Net::CIDR        => 0
   , POSIX::1003      => 0.96
   , Scalar::Util     => 0
   , Socket           => 0
   , Digest::MD5      => 2.53
   }

 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'Generic http server'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
         { repository =>
            { type => 'git'
            , url  => 'https://github.com/markov2/perl5-Any-Daemon-HTTP.git'
            , web  => 'https://github.com/markov2/perl5-Any-Daemon-HTTP'
            }
         , homepage => 'http://perl.overmeer.net/CPAN/'
         , license  => [ 'http://dev.perl.org/licenses/' ]
         }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
EXTENDS		    = ../Any-Daemon
RAWDIR          = ../public_html/any-daemon-http/raw
DISTDIR         = ../public_html/any-daemon-http/source

# for POD
FIRST_YEAR      = 2013
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/any-daemon/

__POSTAMBLE
