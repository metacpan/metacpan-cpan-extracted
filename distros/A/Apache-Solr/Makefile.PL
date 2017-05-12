use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME        => 'Apache::Solr'
  , VERSION     => '1.04'
  , PREREQ_PM   =>
     { Data::Dumper	=> 0
     , Encode           => 0
     , HTTP::Request	=> 0
     , JSON		=> 0
     , Log::Report	=> 0
     , LWP::UserAgent	=> 0
     , Scalar::Util	=> 0
     , Test::More	=> 0
     , Time::HiRes	=> 0
     , URI		=> 0
     , XML::LibXML::Simple => 0
     , MIME::Types      => 0
     }
  , AUTHOR      => 'Mark Overmeer'
  , ABSTRACT    => 'Client for (Lucene) Solr'
  , LICENSE     => 'perl'
  , EXE_FILES   => [  ]
  );

#### the next lines are added for OODoc, which generates the
#### distribution.
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/apache-solr/raw
DISTDIR         = ../public_html/apache-solr/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2012
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net
__POSTAMBLE

