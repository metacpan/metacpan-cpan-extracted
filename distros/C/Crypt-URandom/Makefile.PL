use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Crypt::URandom',
    AUTHOR              => 'David Dick <ddick@cpan.org>',
    VERSION_FROM        => 'lib/Crypt/URandom.pm',
    ABSTRACT_FROM       => 'lib/Crypt/URandom.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Carp'       => 0,
	'English'    => 0,
	($^O eq 'MSWin32') ? ( 'Win32::API' => 0 ) : ( 'FileHandle' => 0 ),
    },
    ($ExtUtils::MakeMaker::VERSION ge '6.30_00' ? # shamelessly copied this from Template Toolkit
    (LICENSE           => 'perl') : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Crypt-URandom-*' },
);
