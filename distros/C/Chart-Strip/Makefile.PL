use ExtUtils::MakeMaker;
WriteMakefile(
              NAME            => 'Chart::Strip',
              VERSION_FROM    => 'Strip.pm',
              ABSTRACT_FROM   => 'Strip.pm',
              AUTHOR          => 'Jeff Weisberg <http://www.tcp4me.com/>',
              PREREQ_PM       => {GD => 0},
);
