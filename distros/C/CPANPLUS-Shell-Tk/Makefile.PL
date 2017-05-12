use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME            => 'CPANPLUS::Shell::Tk',
    VERSION_FROM    => 'lib/CPANPLUS/Shell/Tk.pm', # finds $VERSION
    PREREQ_PM       => {Tk               => 1.0,
                        Tk::MListbox     => 1.11,
                        Tk::Pod          => 4.0,
                        Tk::Splashscreen => 1.0},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT     => 'Graphical User Interface for CPANPLUS using Tk',
       AUTHOR       => 'Bernd Dulfer <bernd@widd.de>') : ()),
    PL_FILES        => {},
);
