use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Algorithm::SpatialIndex::Storage::Redis',
    VERSION_FROM      => 'lib/Algorithm/SpatialIndex/Storage/Redis.pm', # finds $VERSION
    PREREQ_PM         => {
      'Algorithm::SpatialIndex' => '0',
      'Redis'                   => '0',
      'JSON'                    => '0',
      'Scalar::Util'            => '0',
      'Sereal::Encoder'         => '0.36',
      'Sereal::Decoder'         => '0.36',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Algorithm/SpatialIndex/Storage/Redis.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);
