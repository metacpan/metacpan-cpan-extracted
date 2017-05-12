use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Audio::Digest::MP3',
    VERSION_FROM      => 'lib/Audio/Digest/MP3.pm', # finds $VERSION
    PREREQ_PM         => {
        'MPEG::Audio::Frame' => 0,
        'Digest' => 0,
        'Digest::MD5' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Audio/Digest/MP3.pm', # retrieve abstract from module
       AUTHOR         => 'Bart Lateur <bartl@cpan.org>') : ()),
);
