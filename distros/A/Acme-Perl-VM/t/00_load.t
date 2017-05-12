#!perl -w

use strict;
use Test::More tests => 1;

BEGIN { use_ok 'Acme::Perl::VM' }

diag "Testing Acme::Perl::VM/$Acme::Perl::VM::VERSION",
    sprintf ' (APVM_DEBUG=%s)', Acme::Perl::VM::APVM_DEBUG;
