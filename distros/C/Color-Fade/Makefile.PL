use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Color::Fade',
    VERSION_FROM      => 'lib/Color/Fade.pm', # finds $VERSION
    PREREQ_PM         => {},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Color/Fade.pm', # retrieve abstract from module
       AUTHOR         => 'Casey Kirsle <casey-at-cuvou.net>') : ()),
);
