use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::MimeXML',
    'VERSION_FROM' => 'MimeXML.pm', # finds $VERSION
    dist => {COMPRESS => 'gzip', SUFFIX => '.gz', PREOP => 'perl -MPod::Text -e "pod2text \'MimeXML.pm\'" > README'},
);
