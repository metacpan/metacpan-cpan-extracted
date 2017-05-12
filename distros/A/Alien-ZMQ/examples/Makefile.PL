use ExtUtils::MakeMaker;
use Alien::ZMQ;

WriteMakefile(
    NAME         => 'My::Module',
    VERSION_FROM => 'lib/My/Module.pm',
    INC          => Alien::ZMQ::cflags,
    LIBS         => Alien::ZMQ::libs,
    # add more params
);
