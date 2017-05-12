use 5.008009;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Audio::LibSampleRate',
	VERSION_FROM      => 'lib/Audio/LibSampleRate.pm',
	ABSTRACT_FROM     => 'lib/Audio/LibSampleRate.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.8.9',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {},
	INC               => '-Ilibsamplerate/src/',
	MYEXTLIB          => 'libsamplerate/src/.libs/libsamplerate$(LIB_EXT)',
	clean             => { FILES => 'libsamplerate/src/.libs/libsamplerate$(LIB_EXT)' },
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=audio-libsamplerate.git',
		},
	}
);

sub MY::postamble {
'
$(MYEXTLIB): libsamplerate/Makefile.am
	cd libsamplerate && ./configure && CFLAGS=-fPIC `which gmake || echo $(MAKE)`
	cd libsamplerate/src/.libs/ && ar rc libsamplerate$(LIB_EXT) *.o
'
}
