# $Id: Makefile.PL 52 2014-05-21 19:46:02Z adam $

use ExtUtils::MakeMaker;
use strict;
use 5.010;

WriteMakefile(
    'NAME'          => 'Config::Trivial',
    'VERSION_FROM'  => 'lib/Config/Trivial.pm',
    'PREREQ_PM'     => {},
	'PL_FILES'      => {},
     dist           => {
       COMPRESS      => 'gzip -9f',
       SUFFIX        => 'gz'
       },
      ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/Config/Trivial.pm',
       AUTHOR     => 'Dr A. J. Trickett <atrickett@cpan.org>') : ()),
);
