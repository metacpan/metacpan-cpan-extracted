use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'AVLTree',
    AUTHOR           => q{Alessandro Vullo <avullo@cpan.org>},
    VERSION_FROM     => 'lib/AVLTree.pm',
    ABSTRACT_FROM    => 'lib/AVLTree.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.008',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
		       'Test::More' => '0',
		       'Test::LeakTrace' => '0'
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    LIBS      => [''],   # e.g., '-lm',
    DEFINE    => '-DENABLE_DEBUG', # e.g., '-DHAVE_SOMETHING'	      
    INC       => '-Iavltree',     # e.g., '-I/usr/include/other'
    MYEXTLIB  => 'avltree/libavltree$(LIB_EXT)',	      
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'AVLTree-*' },
);

sub MY::postamble {
'
$(MYEXTLIB): avltree/Makefile
	cd avltree && $(MAKE) $(PASSTHRU)
';
}
