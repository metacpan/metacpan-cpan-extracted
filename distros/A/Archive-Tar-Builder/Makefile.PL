use lib '.';

require 'mk/MY.pm';
require 'mk/MY/Makefile.pm';

my $makefile = MY::Makefile->new(
    'srcdir'        => 'src',
    'scan_manifest' => 1
);

$makefile->write(
    'NAME'         => 'Archive::Tar::Builder',
    'VERSION_FROM' => 'lib/Archive/Tar/Builder.pm',
    'AUTHOR'       => 'Alexandra Hrefna Maheu <xan@cpanel.net>',
    'LICENSE'      => 'perl',
    'ABSTRACT'     => 'Provides a braindead tarball builder thingie',
    'PMLIBDIRS'    => ['lib'],
    'CCFLAGS'      => '-D_FILE_OFFSET_BITS=64',

    'PREREQ_PM'      => {},
    'BUILD_REQUIRES' => {
        'Test::Simple'    => '0.44',
        'Test::Exception' => 0
    }
);
