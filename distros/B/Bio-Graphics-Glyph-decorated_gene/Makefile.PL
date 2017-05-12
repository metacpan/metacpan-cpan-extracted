use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bio::Graphics::Glyph::decorated_gene',
    VERSION_FROM      => 'lib/Bio/Graphics/Glyph/decorated_gene.pm', # finds $VERSION
    PREREQ_PM         => { Bio::Graphics => 2.02, List::Util => 0 }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Bio/Graphics/Glyph/decorated_gene.pm', # retrieve abstract from module
       AUTHOR         => 'Christian Frech <frech.christian@gmail.com>') : ()),
);
