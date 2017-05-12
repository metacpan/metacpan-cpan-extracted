
use 5.006000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Continuity::REPL',
    VERSION_FROM      => 'lib/Continuity/REPL.pm',
    ABSTRACT_FROM     => 'lib/Continuity/REPL.pm',
    AUTHOR            => 'Brock Wilcox <awwaiid@thelackthereof.org>',
    LICENSE           => 'Perl',
    PREREQ_PM         => {
      Continuity      => 0.991,
      'Devel::REPL'   => 1.002001,
    },
);
