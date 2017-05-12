use 5.008008;
use ExtUtils::MakeMaker;

our $AUTHOR = -e '.gitignore';
if ($AUTHOR) {
	system( 'pod2text lib/Crypt/OpenSSL/Blowfish/CFB64.pm > README' ) and die "$!";
}

WriteMakefile(
	NAME              => 'Crypt::OpenSSL::Blowfish::CFB64',
	VERSION_FROM      => 'lib/Crypt/OpenSSL/Blowfish/CFB64.pm', # finds $VERSION
	PREREQ_PM         => {}, # e.g., Module::Name => 1.1
	ABSTRACT_FROM     => 'lib/Crypt/OpenSSL/Blowfish/CFB64.pm', # retrieve abstract from module
	AUTHOR            => 'Mons Anderson <mons@cpan.org>',
	LIBS              => ['-lcrypto'], # e.g., '-lm'
	DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	INC               => '-I.', # e.g., '-I. -I/usr/include/other'
);
