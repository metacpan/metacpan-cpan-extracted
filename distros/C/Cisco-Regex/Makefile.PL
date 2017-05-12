use ExtUtils::MakeMaker;
use 5.010;
WriteMakefile(
    'NAME'           => 'Cisco::Regex',
    'VERSION_FROM'   => 'Regex.pm', # finds $VERSION
    'PREREQ_PM'      => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'Regex.pm',
       AUTHOR        => 'Jeremy Kister <http://jeremy.kister.net/>') : ()),
);
