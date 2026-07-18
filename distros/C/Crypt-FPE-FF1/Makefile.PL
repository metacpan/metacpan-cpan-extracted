use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Crypt::FPE::FF1',
  VERSION_FROM => 'lib/Crypt/FPE/FF1.pm',
  ABSTRACT     => 'NIST SP 800-38G FF1 format-preserving encryption (XS binding)',
  AUTHOR       => 'Alexander Pepper <axpepper@gmail.com>',
  LICENSE      => 'mit',
  INC          => '-Icsrc',
  LIBS         => ['-lcrypto'],
  XS           => { 'FF1.xs' => 'FF1.c' },            # top-level XS
  OBJECT       => '$(O_FILES) csrc/ff1.o csrc/fpe_locl.o',  # force-link the C OBJs
  DEFINE       => '-Wno-deprecated-declarations',
);

sub MY::postamble { return <<'MAKE_FRAG';
ppport.h:
	$(PERL) -MDevel::PPPort -e "Devel::PPPort::WriteFile(qw(ppport.h))"

FF1.c: ppport.h

csrc/ff1.o: csrc/ff1.c
	$(CCCMD) $(CCCDLFLAGS) -c csrc/ff1.c -o csrc/ff1.o

csrc/fpe_locl.o: csrc/fpe_locl.c
	$(CCCMD) $(CCCDLFLAGS) -c csrc/fpe_locl.c -o csrc/fpe_locl.o
MAKE_FRAG
}

