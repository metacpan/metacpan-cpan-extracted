# $Id: Makefile.PL,v 1.2 2004/09/19 19:04:59 simonflack Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Class::Publisher',
    'VERSION_FROM'	=> 'lib/Class/Publisher.pm',
    'PREREQ_PM'		=> { 'Class::ISA' => 0.32,
                         'Scalar::Util' => 0,
                         'Test::More' => 0.45 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/Class/Publisher.pm',
       AUTHOR     => 'Simon Flack') : ()),
);
