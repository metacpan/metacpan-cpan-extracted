use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Acme::RedShirt',
    VERSION_FROM => 'lib/Acme/RedShirt.pm', # finds $VERSION
    AUTHOR       => 'Timm Murray (tmurray@agronomy.org)',
    ABSTRACT     => 'Acme::RedShirt',
);
