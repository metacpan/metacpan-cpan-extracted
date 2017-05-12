use 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Business::Payment::SwissESR',
  VERSION_FROM => 'lib/Business/Payment/SwissESR.pm',
  ABSTRACT     => 'Create PDF invoices according to the Swiss ESR standard',
  AUTHOR       => 'Tobias Oetiker <tobi@oetiker.ch>',
  LICENSE      => 'gpl_3',
  PREREQ_PM    => {
    'Mojolicious' => '3.0'
  },
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license     => 'http://opensource.org/licenses/GPL-3.0',
      repository  => 'https://github.com/oetiker/business-payment-swissesr',
      bugtracker  => 'https://github.com/oetiker/business-payment-swissesr/issues'
    },
    no_index => {directory => ['t','example','setup']}
  },
# EXE_FILES => ['script/hypnotoad', 'script/mojo', 'script/morbo'],
  test => {TESTS => 't/*.t'}
);
