use ExtUtils::MakeMaker;

%mods = ( 
  'Curses'            => 1.06,
  'Curses::Widgets'   => 1.997,
  'Curses::Forms'     => 1.997,
);

WriteMakefile(
  NAME	    => 'Curses::Application',
  AUTHOR    => 'Arthur Corliss <corliss@digitalmages.com>',
  ABSTRACT  => 
    'Curses application development framework',
  VERSION   => '0.2',
  PREREQ_PM => \%mods,
);

