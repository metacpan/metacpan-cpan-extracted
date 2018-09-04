#!/usr/bin/env perl

#:TAGS:

use strict;  use warnings;

BEGIN { # XXX
    if ($ENV{EMACS}) {
        chdir '..' until -d 't';
        use lib qw(blib/lib blib/arch)
    }
}

# use Data::Dump; # XXX

if (0) { # XXX
    no strict 'refs';
    diag($_), $_->() for grep { /^test_/ } keys %::
}
################################################################################
use Test::More;
use Test::Warn;
use Config;

use Bit::Twiddling ':all';

# use File::Spec; Test::More->builder->output(File::Spec->devnull);

for ( [0, 0], [1, 1], [2, 1], [3, 2] ) {
    my ($input, $output) = @$_;
    is count_set_bits($input), $output, "count_set_bits($input) = $output";
}

is count_set_bits("12"), 2, 'count_set_bits("12") returns 2';

warning_like {
    is count_set_bits(""), 0, 'count_set_bits("") returns 0'
} qr/Argument "" isn't numeric in subroutine entry/,
  'count_set_bits("") gives a warning';

warning_like {
    is count_set_bits("x"), 0, 'count_set_bits("x") returns 0'
} qr/Argument "x" isn't numeric in subroutine entry/,
  'count_set_bits("x") gives a warning';

warning_like {
    is count_set_bits(undef), 0, 'count_set_bits(undef) returns 0';
} qr/Use of uninitialized value in subroutine entry/,
  'count_set_bits(undef) gives a warning';

SKIP: {
    skip q(perl not compiled with 'use64bitall')
      unless defined $Config{use64bitall};

    is count_set_bits(-1), 64, 'count_set_bits(-1) returns 64';
}

done_testing;
