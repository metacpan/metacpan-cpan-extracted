use ExtUtils::MakeMaker;
$Verbose = 1;
WriteMakefile(
    OPTIMIZE => '-O3',
    NAME   => 'Crypt::UnixCrypt_XS::fcrypt',
    SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
    clean  => {'FILES' => 'libfcrypt$(LIB_EXT)'},
);

sub MY::top_targets {'
all :: static

pure_all :: static

static ::       libfcrypt$(LIB_EXT)

libfcrypt$(LIB_EXT): $(O_FILES)
	$(AR) cr libfcrypt$(LIB_EXT) $(O_FILES)
	$(RANLIB) libfcrypt$(LIB_EXT)
'.($ExtUtils::MakeMaker::VERSION >= 7.16?'

dynamic ::
	$(NOECHO) $(NOOP)
':''); #https://rt.cpan.org/Ticket/Display.html?id=117800
               }
                              
                              
                              
                              
                              
