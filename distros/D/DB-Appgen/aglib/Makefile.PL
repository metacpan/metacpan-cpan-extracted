use ExtUtils::MakeMaker;
WriteMakefile(
 NAME   => 'DB::Appgen::aglib',
 clean  => {'FILES' => 'libappgen$(LIBEEXT)'},
);
 
sub MY::top_targets {
'
all :: static

pure_all :: static

static ::       libappgen$(LIB_EXT)

libappgen$(LIB_EXT): $(O_FILES)
	$(AR) cr libappgen$(LIB_EXT) $(O_FILES)
	$(RANLIB) libappgen$(LIB_EXT)

';
}                         
