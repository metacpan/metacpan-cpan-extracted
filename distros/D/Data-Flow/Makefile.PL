use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Data::Flow',
    'dist'      => { COMPRESS => gzip, SUFFIX => '.gz'},
    'VERSION_FROM' => 'Flow.pm', # finds $VERSION
);
