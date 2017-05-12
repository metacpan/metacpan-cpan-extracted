use 5.008009;
use inc::Module::Install;
name 'CSS-Croco';
all_from 'lib/CSS/Croco.pm';
requires 'URI';
repository 'http://developers.rambler.ru/svn/perlmodules/CSS-Croco';
system("pkg-config libcroco-0.6") and print STDERR "NA: libcroco-0.6 is not available. Please intall it and try again\n";
WriteMakefile(
    LIBS => [ `pkg-config --libs libcroco-0.6` ],
    INC               => '-I. ' . `pkg-config --cflags libcroco-0.6`,
    XSOPT => '-prototypes',
);
