use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Crypt::XXTEA::CImpl',
    VERSION_FROM      => 'lib/Crypt/XXTEA/CImpl.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Crypt/XXTEA/CImpl.pm', # retrieve abstract from module
       AUTHOR         => 'Ildar Efremov <iefremov@2reallife.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    OBJECT            => 'CImpl.o xxcrypt.o ', # link all the C files too
);
