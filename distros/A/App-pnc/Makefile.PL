
use ExtUtils::MakeMaker;

WriteMakefile(NAME          => 'App::pnc',
              VERSION_FROM  => 'lib/App/pnc.pm',
              PREREQ_PM     => {},
              ABSTRACT_FROM => 'lib/App/pnc.pm',
              AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>');
