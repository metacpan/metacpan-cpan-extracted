use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    AUTHOR            => 'Kazuki MATSUDA',
    NAME              => 'Catalyst::Plugin::Text::Xatena',
    VERSION_FROM      => 'lib/Catalyst/Plugin/Text/Xatena.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.008 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/Plugin/Text/Xatena.pm', # retrieve abstract from module
       AUTHOR         => 'Kazuki MATSUDA <kazukima@cpan.org>') : ()),
    VERSION           => '0.02',
    PREREQ_PM         => {
	'Text::Xatena'              => 0,
	'Class::Data::Inheritable'  => 0,
    }
);
