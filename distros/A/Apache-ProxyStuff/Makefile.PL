use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::ProxyStuff',
    'VERSION_FROM' => 'ProxyStuff.pm', # finds $VERSION
);
