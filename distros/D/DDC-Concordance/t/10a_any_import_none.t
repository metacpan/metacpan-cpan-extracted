##-*- Mode: CPerl -*-
use Test::More tests=>2;

##-- +2: none
use DDC::Any ':none';
ok(!defined($DDC::Any::WHICH), 'use :none - WHICH undefined');
ok(!exists($DDC::Any::{'Constants::'}), 'use :none - no Constants sub-package');
