use ExtUtils::MakeMaker;
$Verbose = 1;
WriteMakefile(
	NAME => 'Cartography::Projection::GCTP::gctpc',
	SKIP => [qw(all static static_lib dynamic dynamic_lib)],
	clean => {'FILES' => 'libgctpc$(LIB_EXT)'},
);

sub MY::top_targets {
	'
all :: static

pure_all :: static

static :: libgctpc$(LIB_EXT)

libgctpc$(LIB_EXT): $(O_FILES)
	$(AR) cr libgctpc$(LIB_EXT) $(O_FILES)
	$(RANLIB) libgctpc$(LIB_EXT)
';
}
