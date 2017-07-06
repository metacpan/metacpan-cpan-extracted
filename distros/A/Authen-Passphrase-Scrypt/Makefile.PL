use 5.014000;
use ExtUtils::MakeMaker;

my @link_with = map { 'scrypt-1.2.1/'.$_ } qw,
lib/crypto/libscrypt_sse2_a-crypto_scrypt_smix_sse2.o
lib/crypto/crypto_scrypt.o
lib/crypto/crypto_scrypt_smix.o
lib/scryptenc/scryptenc.o
lib/scryptenc/scryptenc_cpuperf.o
lib/util/memlimit.o
libcperciva/alg/sha256.o
libcperciva/cpusupport/cpusupport_x86_aesni.o
libcperciva/cpusupport/cpusupport_x86_sse2.o
libcperciva/crypto/libcperciva_aesni_a-crypto_aes_aesni.o
libcperciva/crypto/crypto_aes.o
libcperciva/crypto/crypto_aesctr.o
libcperciva/crypto/crypto_entropy.o
libcperciva/util/asprintf.o
libcperciva/util/entropy.o
libcperciva/util/getopt.o
libcperciva/util/humansize.o
libcperciva/util/insecure_memzero.o
libcperciva/util/readpass.o
libcperciva/util/warnp.o,;

WriteMakefile(
	NAME              => 'Authen::Passphrase::Scrypt',
	VERSION_FROM      => 'lib/Authen/Passphrase/Scrypt.pm',
	ABSTRACT_FROM     => 'lib/Authen/Passphrase/Scrypt.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Authen::Passphrase       0
		   Class::Accessor::Fast    0
		   Data::Entropy::Algorithms 0/,
	},
	INC               => '-I. -Iscrypt-1.2.1',
	LIBS              => ['-lcrypto'],
	MYEXTLIB          => 'scrypt-1.2.1/libscrypt_sse2.a',
	LDFROM => "\$(OBJECT) @link_with",
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=authen-passphrase-scrypt.git',
		},
	}
);

sub MY::postamble {
'
$(MYEXTLIB): scrypt-1.2.1/configure
	cd scrypt-1.2.1 && ./configure && `which gmake || echo $(MAKE)` CFLAGS+=-fPIC
'
}
