#!/usr/bin/env perl

#:TAGS:

use 5.010;

use strict;  use warnings;

BEGIN { # XXX
    if ($ENV{EMACS}) {
        chdir '..' until -d 't';
        use lib 'lib';
    }
}
################################################################################
use Test::More;

eval 'use Test::CPAN::Changes';

plan skip_all => 'Test::CPAN::Changes required for this test' if $@;

changes_ok();
