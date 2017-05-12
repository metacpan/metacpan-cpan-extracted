use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'CIPP::Doc',
    'VERSION_FROM' => 'Doc.pm', # finds $VERSION
    'dist' => {
        COMPRESS => "gzip",
        SUFFIX => "gz"
    }
);
