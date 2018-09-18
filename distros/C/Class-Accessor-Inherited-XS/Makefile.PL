use 5.010001;
use Config;
use ExtUtils::MakeMaker;

#system 'pod2text lib/Class/Accessor/Inherited/XS.pm > README';
#system 'pod2github lib/Class/Accessor/Inherited/XS.pm > README.md';

my $CCFLAGS = join(' ',$Config{ccflags},'-x c++', '-fno-exceptions', '-fno-rtti');

WriteMakefile(
    NAME            => 'Class::Accessor::Inherited::XS',
    VERSION_FROM    => 'lib/Class/Accessor/Inherited/XS.pm',
    AUTHOR          => ['Vladimir Timofeev <vovkasm@crazypanda.ru>', 'Sergey Aleynikov <randir@cpan.org>'],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'   => 6.64,
    },
    PREREQ_PM       => {
        'XSLoader'    => 0,
        'Carp'        => 0,
    },
    TEST_REQUIRES   => {
        'Test::More'  => 0,
        'Test::Deep'  => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/vovkasm/Class-Accessor-Inherited-XS',
            bugtracker => 'https://github.com/vovkasm/Class-Accessor-Inherited-XS/issues',
        },
        dynamic_config => 0,
    },
    ABSTRACT_FROM   => 'lib/Class/Accessor/Inherited/XS.pm',
    LICENSE         => 'perl',
    MIN_PERL_VERSION=> 5.010001,
    CCFLAGS         => $CCFLAGS,
    #LIBS            => ['-lstdc++'],
    #XSOPT           => '-C++',
);

{
    package MY;

    sub postamble { '$(OBJECT) : '.join(' ', glob('xs/*.h')) }
}

