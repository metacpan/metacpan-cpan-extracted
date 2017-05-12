use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR' => 'Peter G. Marshall (mitd@mitd.com)',
    'NAME'	=> 'Apache::TimedRedirect',
    'VERSION_FROM' => 'TimedRedirect.pm', # finds $VERSION
    'dist' => {COMPRESS=>"gzip", SUFFIX=>"gz"},	
    'PREREQ_PM' => { 'Time::Period' => '1.20'},
);
