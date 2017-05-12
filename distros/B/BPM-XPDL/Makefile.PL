use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'BPM::XPDL'
 , VERSION	=> '0.93'
 , PREREQ_PM    =>
   { XML::Compile         => '1.51'
   , XML::Compile::Cache  => '0.995'
   , XML::Compile::Tester => '0.05'
   , Log::Report          => '0.23'

   , Test::More           => '0.54'
   , Test::Pod            => '1.00'
   }

 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'BPM/XPDL standard'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/bpm-xpdl/raw
DISTDIR         = ../public_html/bpm-xpdl/source
LICENSE         = artistic

EXTENDS         = ../XMLCache:../XMLCompile:../XMLSimple

# for POD
FIRST_YEAR      = 2009
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net
__POSTAMBLE


