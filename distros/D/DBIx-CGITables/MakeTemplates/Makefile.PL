use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'DBIx::CGITables::MakeTemplate',
    'dist' => {COMPRESS => 'gzip -9', SUFFIX => '.gz', DIST_DEFAULT => 'all tardist' }
);
