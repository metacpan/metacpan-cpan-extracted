use ExtUtils::MakeMaker;

%mods = ( 
  'Curses'            => 1.06,
  'Curses::Widgets'   => 1.997,
);

WriteMakefile(
  NAME	    => 'Curses::Forms',
  AUTHOR    => 'Arthur Corliss <corliss@digitalmages.com>',
  ABSTRACT  => 
    'High level access to Curses forms for use with Curses::Widgets',
  VERSION   => '1.997',
  PREREQ_PM => \%mods,
);

