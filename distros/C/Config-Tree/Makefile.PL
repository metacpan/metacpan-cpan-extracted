#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME           => 'Config::Tree',
  AUTHOR         => 'Matthew King (cpan:CHOHAG) <chohag@jtan.com>',
  ABSTRACT_FROM  => 'lib/Config/Tree.pm',
  VERSION_FROM   => 'lib/Config/Tree.pm',
  LICENSE        => 'wtfpl_2',
  PREREQ_PM      => {
    # TODO: Find out minimum versions of these
    'List::Util'           => '1.29',
    'Scalar::Util'         => '0',
    'strictures'           => '2',
    'Syntax::Keyword::Try' => '0',
  },
);
