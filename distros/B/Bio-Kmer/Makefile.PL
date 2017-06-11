use strict;
use warnings;
 
use 5.008;
 
use ExtUtils::MakeMaker;

# Some help from 
# http://blogs.perl.org/users/michal_wojciechowski/2011/11/github-friendly-readme-files-with-extutils-makemaker-and-module-build.html
my $preop =
  'perldoc -uT $(VERSION_FROM) | tee $(DISTVNAME)/README.pod > README.pod;' .
  'pod2text README.pod | tee $(DISTVNAME)/README > README';

WriteMakefile
(
  NAME         => 'Bio::Kmer',
  VERSION_FROM => 'lib/Bio/Kmer.pm',
  PREREQ_PM    => {
    'File::Basename' => 0,
    'File::Temp'     => 0,
    'Data::Dumper'   => 0,
    'IO::Uncompress::Gunzip' => 0,
    'threads'        => 0,
    'threads::shared'=> 0,
    'Thread::Queue'  => 0,
    'Exporter'       => 0,
  },
  BUILD_REQUIRES => {
    'Test::More'     => 0.47,
  },
  dist           => {
    COMPRESS => "gzip -9f",
    SUFFIX   => "gz",
    PREOP    => $preop,
  },
);

