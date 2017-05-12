use strict;
use warnings;
 
use 5.008;
 
use ExtUtils::MakeMaker;
WriteMakefile
(
  NAME         => 'Bio::Kmer',
  VERSION_FROM => 'lib/Bio/Kmer.pm',
  PREREQ_PM    => {
    'File::Basename' => 1,
    'File::Temp'     => 1,
    'Data::Dumper'   => 1,
    'IO::Uncompress::Gunzip' => 1,
    'threads'        => 1,
    'threads::shared'=> 1,
    'Thread::Queue'  => 1,
    'Exporter'       => 1,
  },
  BUILD_REQUIRES => {
    'Test::More'     => 0.47,
  },
);

