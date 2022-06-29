use ExtUtils::MakeMaker;

# Avoid the loading of a huge number of modules on clients.  When
# someone runs the script as client, it will get a problem with
# missing "CPAN::Checksums", which is not a problem.

eval "require CPAN::Site";
if(!$@ && $CPAN::Site::VERSION <= 1.01 && !$ENV{MARKOV_DEVEL})
{   warn <<__WARN;

*** the interface of CPAN::Site has changed a lot with release 1.01
*** please re-read the documentation.

__WARN
    sleep 3
}

WriteMakefile
 ( NAME       => 'CPAN::Site'
 , ABSTRACT   => 'adding site local modules'
 , VERSION_FROM => 'lib/CPAN/Site.pm'

 , EXE_FILES  => [ 'bin/cpansite' ]

 , AUTHOR     => 'Mark Overmeer'
 , PREREQ_PM  =>
   { Archive::Tar        => 1.00
   , Archive::Zip        => 0
   , CPAN::Checksums     => 2.14
   , Getopt::Long        => 0
   , HTTP::Date          => 0
   , IO::Zlib            => 0
   , Log::Report         => 0.25
   , LWP                 => 6.00
   , LWP::Protocol::https => 6.00
   , Test::More          => 0.82
   , Test::TempDir::Tiny => 0.018
   , version             => 0.76
   }
 , LICENSE    => 'perl_5'

  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-CPAN-Site.git'
              , web  => 'https://github.com/markov2/perl5-CPAN-Site'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
 );

#### the next lines are added for OODoc, which generates the
#### distribution.
sub MY::postamble { <<__POSTAMBLE }

# for DIST
RAWDIR          = ../public_html/cpan-site/raw
DISTDIR         = ../public_html/cpan-site/source
LICENSE         = perl

# for POD
FIRST_YEAR      = 1998,2005
EMAIL           = markov\@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/
__POSTAMBLE
