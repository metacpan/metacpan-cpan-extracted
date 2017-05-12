use ExtUtils::MakeMaker;
$Verbose = 1;
WriteMakefile(
    NAME   => 'CGI::AppToolkit::Template::templatelib',
    LIBS   => [qw'-lstdc++'],   # e.g., '-lm'
#    SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
    SKIP   => [qw(all static dynamic)],
    clean  => {'FILES' => 'libtemplatelib$(LIBEEXT)'},
    CC     => 'c++',
);

sub MY::top_targets {
        '
all :: static

pure_all :: static

static ::       libtemplatelib$(LIB_EXT)

libtemplatelib$(LIB_EXT): $(O_FILES)
	$(AR) cr libtemplatelib$(LIB_EXT) $(O_FILES)
	$(RANLIB) libtemplatelib$(LIB_EXT)

';
}
