#! perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile (
  NAME => 'Business::IBAN::NL::BIC',
  VERSION_FROM => 'lib/Business/IBAN/NL/BIC.pm',
  ABSTRACT_FROM => 'lib/Business/IBAN/NL/BIC.pm',
  AUTHOR => 'Sebastiaan Hoogeveen <pause-zebaz@nederhost.nl>',
);
