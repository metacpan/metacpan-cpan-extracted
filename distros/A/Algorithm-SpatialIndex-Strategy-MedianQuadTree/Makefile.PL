use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Algorithm::SpatialIndex::Strategy::MedianQuadTree',
    VERSION_FROM      => 'lib/Algorithm/SpatialIndex/Strategy/MedianQuadTree.pm', # finds $VERSION
    PREREQ_PM         => {
      'Algorithm::SpatialIndex'    => '0.05',
      'Statistics::CaseResampling' => '0.06',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Algorithm/SpatialIndex/Strategy/MedianQuadTree.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);
