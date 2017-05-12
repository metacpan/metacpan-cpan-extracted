use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Convert::EBCDIC',
    'VERSION_FROM' => 'lib/Convert/EBCDIC.pm', # finds $VERSION
    dist => { COMPRESS => 'gzip -9f' },
);
