use ExtUtils::MakeMaker;
use Alien::Bit;
use File::Spec::Functions qw(catfile);

# Build main Bit::Set library
WriteMakefile(
    NAME             => "Bit::Set",
    VERSION_FROM     => catfile("lib", "Bit", "Set.pm"),
    ABSTRACT_FROM    => catfile("lib", "Bit", "Set.pm"),
    MIN_PERL_VERSION => "5.38.0",
    XSMULTI          => 1,
    OBJECT           => '$(BASEEXT)$(OBJ_EXT)',
    TYPEMAPS         => ['typemap'],
    INC              => join(' ', Alien::Bit->cflags, '-I.', '-Ilib/Bit/Set'),
    LIBS             => [ Alien::Bit->libs ],
);
