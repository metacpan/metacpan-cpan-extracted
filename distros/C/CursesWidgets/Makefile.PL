use ExtUtils::MakeMaker;

%mods = ( 
  Curses  => 1.06,
  );

WriteMakefile(
  NAME        => 'Curses::Widgets',
  AUTHOR      => 'Arthur Corliss <corliss@digitalmages.com>',
  ABSTRACT    => 
    'High level access to widgets for rapid interface design.',
  VERSION     => '1.997',
  PREREQ_PM   => \%mods
);


