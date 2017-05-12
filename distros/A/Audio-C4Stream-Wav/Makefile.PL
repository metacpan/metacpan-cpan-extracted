use 5.010001;
use Inline::MakeMaker;

WriteMakefile(
    NAME              => 'Audio::C4Stream::Wav',
    VERSION_FROM      => 'lib/Audio/C4Stream/Wav.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Audio/C4Stream/Wav.pm', # retrieve abstract from module
       AUTHOR         => 'cloud4pc <adeamara@cloud4pc.com>') : ()),
);
