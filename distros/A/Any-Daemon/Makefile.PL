#!/usr/bin/env perl
use ExtUtils::MakeMaker;

use 5.008;

my $version = '0.95';

WriteMakefile
 ( NAME	 	=> 'Any::Daemon'
 , VERSION	=> $version
 , PREREQ_PM    =>
    { Test::More            => 0.80
    , File::Spec            => 0
    , English               => 0

    # only the example requires the full Log::Report
    , Log::Report::Optional => '1.06'
    }
 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'General purpose daemon'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
         { repository =>
            { type => 'git'
            , url  => 'https://github.com/markov2/perl5-Any-Daemon.git'
            , web  => 'https://github.com/markov2/perl5-Any-Daemon'
            }
         , homepage => 'http://perl.overmeer.net/CPAN/'
         , license  => [ 'http://dev.perl.org/licenses/' ]
         }
      }
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/any-daemon/raw
DISTDIR         = ../public_html/any-daemon/source

# for POD
FIRST_YEAR      = 2011
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/
EXTENDS			= ../../perl/AnyHTTP
__POSTAMBLE
