use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'Data::DublinCore'
 , VERSION     	=> '1.00'
 , PREREQ_PM    =>
   { XML::Compile         => '1.50'
   , XML::Compile::Cache  => '1.04'
   , XML::LibXML::Simple  => '0.13'
   , Log::Report          => '0.23'

   , Test::More           => '0.54'
   , Test::Pod            => '1.00'
   }

 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'DublinCore XML schemas'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/data-dublincore/raw
DISTDIR         = ../public_html/data-dublincore/source
LICENSE         = artistic

EXTENDS         = ../XMLCache:../XMLCompile:../XMLSimple

# for POD
FIRST_YEAR      = 2009
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net
__POSTAMBLE

