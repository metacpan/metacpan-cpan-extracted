use 5.016003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Crypt::Digest::Scrypt',
    VERSION_FROM      => 'lib/Crypt/Digest/Scrypt.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Crypt/Digest/Scrypt.pm', # retrieve abstract from module
    AUTHOR            => 'Pavel Gulchuk <gul@gul.kiev.ua>',
    LIBS              => ['-lcrypto'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
