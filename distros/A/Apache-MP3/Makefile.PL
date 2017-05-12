use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME		=> 'Apache::MP3',
    AUTHOR              => 'Lincoln Stein <lstein@cshl.org>',
    ABSTRACT            => 'mod_perl class for generating browsable MP3 directory lists',
    ABSTRACT_FROM       => 'MP3.pm',
    VERSION             => '4.00',
    PREREQ_PM		=> {
			    MP3::Info             => 0.8,
			    Apache2::RequestRec   => 2.000001,
			    Audio::Wav            => 0.02,
			    Ogg::Vorbis::Header   => 0.02, # b/c Ogg::Vorbis can't be found by CPAN shell
			    Inline::MakeMaker     => 0.01, # required by Ogg::Vorbis, but not specified in it's makefile, causing CPAN shell install to fail.
			    Locale::Maketext      => 1.03,
			    CGI::Session          => 4.03,
			   }, # e.g., Module::Name => 1.1
);

1;
