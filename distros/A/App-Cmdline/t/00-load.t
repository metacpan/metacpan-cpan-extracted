#!/usr/bin/env perl
use strict;
use warnings;

#use Test::More qw(no_plan);
use Test::More tests => 1;

BEGIN {
    use lib 't';
    use_ok ('App::testapp');
}
## no critic
no strict;    # because the $VERSION will be added only when
no warnings;  # the distribution is fully built up
diag( "Testing App::Cmdline $App::Cmdline::VERSION, Perl $], $^X" );
