use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Acme::Curses::Marquee::Extensions',
    VERSION_FROM      => 'lib/Acme/Curses/Marquee/Extensions.pm',
    PREREQ_PM         => {
			  Acme::Curses::Marquee => undef,
			  Curses => undef,
			  Every => undef,
			  Term::ANSIColor => undef,
			  Text::FIGlet => 2.00,
			 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Acme/Curses/Marquee/Extensions.pm') : ()),
);
