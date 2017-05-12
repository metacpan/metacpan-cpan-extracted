use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Crypt::OpenSSL::Common',
    VERSION_FROM      => 'lib/Crypt/OpenSSL/Common.pm',
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Crypt/OpenSSL/Common.pm', # retrieve abstract from module
    AUTHOR            => 'Salvador Ortiz Garcia <sog@msg.com.mx>',
    LIBS              => ['-lssl -lcrypto'],
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
        # Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);

