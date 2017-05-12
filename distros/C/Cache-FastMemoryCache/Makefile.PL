use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Cache::FastMemoryCache',
    'VERSION_FROM'	=> 'FastMemoryCache.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Cache::Cache' => 0,
                         'Cache::MemoryCache' => 0,
                       }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'FastMemoryCache.pm', # retrieve abstract from module
       AUTHOR     => 'John Millaway <millaway@acm.org>') : ()),
);
