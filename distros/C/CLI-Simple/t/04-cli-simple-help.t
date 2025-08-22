#!/usr/bin/env perl

# Test::Exit must be compiled before other code that calls exit
use Test::Exit;
use Test::More;
use Test::Output;
use Pod::Usage;

package Foo;

use strict;
use warnings;

use parent qw(CLI::Simple);

=pod

=head1 USAGE

Some usage 

=head2 Options

 blah blah

=cut

package main;

use strict;
use warnings;

local @ARGV = qw(--help);

local $ENV{PAGER}   = q{};
local $ENV{PERLDOC} = q{};

########################################################################
subtest 'help' => sub {
########################################################################
  stdout_like(
    sub {
      exits_ok {
        Foo->new( commands => { foo => \&foo }, option_specs => ['help'] );
      }, 'exits ok';
    },
    qr/^Usage/xsmi
  );
};

done_testing;

1;

