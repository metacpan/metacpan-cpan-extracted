use ExtUtils::MakeMaker;

$Verbose = 1;
WriteMakefile(
	      NAME   => 'AVLTree::avltree',
	      SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
	      clean  => {'FILES' => 'libavltree$(LIB_EXT)'},
	     );

sub MY::top_targets {
'
all :: static
pure_all :: static
static ::       libavltree$(LIB_EXT)
libavltree$(LIB_EXT): $(O_FILES)
	$(AR) cr libavltree$(LIB_EXT) $(O_FILES)
	$(RANLIB) libavltree$(LIB_EXT)
';
}
