use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'CGI::Untaint::date',
    VERSION_FROM	=> 'lib/CGI/Untaint/date.pm', 
    PREREQ_PM		=> { 
                              CGI::Untaint => 0.07,
                              Date::Manip  => 5.00,
                              Date::Simple => 0.01,
                           }, 
    ($] > 5.005 ? () : (
      ABSTRACT_FROM => 'lib/CGI/Untaint/date.pm', 
      AUTHOR        => 'Tony Bowden <kasei@tmtm.com>',
    )),
);
