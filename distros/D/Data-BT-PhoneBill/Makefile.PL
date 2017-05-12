use ExtUtils::MakeMaker;

WriteMakefile(
  NAME		=> 'Data::BT::PhoneBill',
  VERSION_FROM	=> 'lib/Data/BT/PhoneBill.pm', 
  PREREQ_PM		=> { 
    'Test::More' => 0.17,
    'Text::CSV_XS' => 0,
    'Date::Simple' => 0,
    'IO::File' => 0,

  }, 
  ($] > 5.005 ? () : (
    ABSTRACT_FROM => 'lib/Data/BT/PhoneBill.pm', 
    AUTHOR        => 'Tony Bowden <kasei@tmtm.com>',
  )),
);
