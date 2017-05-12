use ExtUtils::MakeMaker;
$Verbose = 1;
WriteMakefile(
	NAME   => 'Audio::AMaMP::amamp_binding',
	SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
	clean  => {'FILES' => 'libamamp_binding$(LIB_EXT)'},
);

sub MY::top_targets {
'
all :: static

pure_all :: static

static ::       libamamp_binding$(LIB_EXT)

libamamp_binding$(LIB_EXT): $(O_FILES)
	$(AR) ' . ($^O =~ /MSWin32/ ? '' : 'cr ') . 'libamamp_binding$(LIB_EXT) $(O_FILES)
	$(RANLIB) libamamp_binding$(LIB_EXT)

';
}

