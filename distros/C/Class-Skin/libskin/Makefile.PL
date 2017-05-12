use ExtUtils::MakeMaker;
$Verbose = 0;
WriteMakefile(
	      NAME       => 'Class::Skin::skin',
	      SKIP       => [qw(all static static_lib dynamic dynamic_lib)],
	      LIBS       => ['-lfl -lm'],
	      INC        => '',
	      clean      => {'FILES' => 'libskin$(LIBEEXT) y.output lex.yy.c y.tab.c y.tab.h'},
              OPTIMIZE   => '-O' # '-g' 
	      );

sub MY::top_targets {
'
LEX = flex -I
YACC = byacc

all :: static

pure_all :: static

static ::       libskin$(LIB_EXT)

libskin$(LIB_EXT): y.tab.o lex.yy.o
	$(AR) cr libskin$(LIB_EXT) lex.yy.o y.tab.o
	$(RANLIB) libskin$(LIB_EXT)

y.tab.c y.tab.h: skin.y
	$(YACC) -v -d skin.y

lex.yy.o: lex.yy.c
	$(CC) -c lex.yy.c -O -I/usr/lib/glib/include

lex.yy.c: skin.l
	$(LEX) skin.l

';
}

