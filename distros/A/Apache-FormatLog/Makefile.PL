use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::FormatLog',
    'VERSION_FROM' => 'FormatLog.pm', # finds $VERSION
);