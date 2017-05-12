use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Audio::GtkGramofile',
    VERSION_FROM      => 'GtkGramofile.pm', # finds $VERSION
    PREREQ_PM         => {Audio::Gramofile => 0.08, Config::IniFiles => 2.00, Gtk2 => 1.00}, # e.g., Module::Name => 1.1
    EXE_FILES         => [ qw(gtkgramo) ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'GtkGramofile.pm', # retrieve abstract from module
       AUTHOR         => 'Bob Wilkinson <bob@fourtheye.org>') : ()),
);
