use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Crypt::License::Notice',
    'VERSION_FROM'	=> 'Notice.pm', # finds $VERSION
    'clean'             => {FILES       => "*.bln* *.tmp"},
    'dist'		=> {COMPRESS=>'gzip', SUFFIX=>'gz'}
);
