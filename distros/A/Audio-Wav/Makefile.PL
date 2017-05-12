use ExtUtils::MakeMaker;

my %makefile = (
    NAME         => 'Audio::Wav',
    VERSION_FROM => 'Wav.pm', # finds $VERSION
);
WriteMakefile(%makefile);

