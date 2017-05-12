use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME           => 'AnyEvent::Pg::Pool::Multiserver',
  VERSION_FROM   => 'lib/AnyEvent/Pg/Pool/Multiserver.pm',
  PREREQ_PM      => {
    'AnyEvent'           => '7.07',
    'Future'             => '0.27',
    'AnyEvent::Pg::Pool' => '0.14',
    'Params::Validate'   => '1.10',
    'Class::XSAccessor'  => '1.19',
  },
  ABSTRACT_FROM  => 'lib/AnyEvent/Pg/Pool/Multiserver.pm',
  AUTHOR         => 'Andrey Kuzmin <kak-tus@mail.ru>'
);
