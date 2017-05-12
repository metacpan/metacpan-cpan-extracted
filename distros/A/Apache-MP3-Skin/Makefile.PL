use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME		=> 'Apache::MP3::Skin',
    AUTHOR              => 'Robert Graff <rgraff@apachemp3.com>',
    ABSTRACT            => 'mod_perl class for generating browsable MP3 directory lists with templated skins',
    ABSTRACT_FROM       => 'Skin.pm',
    VERSION_FROM	=> 'Skin.pm', # finds $VERSION
    PREREQ_PM		=> { 
			    Apache::MP3  => 2.12,
			    Apache     => 1.14,
                            HTML::Template => 2.0,
			   }, # e.g., Module::Name => 1.1
);
