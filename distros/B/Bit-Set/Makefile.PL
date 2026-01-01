use ExtUtils::MakeMaker;
use Alien::Bit;

WriteMakefile(
    NAME             => "Bit::Set",
    VERSION_FROM     => "lib/Bit/Set.pm",
    ABSTRACT_FROM    => "lib/Bit/Set.pm",
    MIN_PERL_VERSION => "5.38.0",
    XS               => {
        'Set.xs'            => 'Set.c',
    },
    OBJECT   => '$(BASEEXT)$(OBJ_EXT)',
    TYPEMAPS => ['typemap'],
    INC      => Alien::Bit->cflags,
    LIBS     => [ Alien::Bit->libs ],
);
