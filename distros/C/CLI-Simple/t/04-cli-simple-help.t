#!/usr/bin/env perl

# Test::Exit must be compiled before other code that calls exit
use Test::Exit;
use Test::More;
use Test::Output;
use Pod::Usage;

BEGIN {
  use_ok( qw(CLI::Simple), qw($AUTO_HELP) );
}

package Foo;

use strict;
use warnings;

our @ISA = qw(CLI::Simple);

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

BEGIN {
  use_ok( qw(CLI::Simple), qw($AUTO_HELP) );
}

########################################################################
subtest 'help' => sub {
########################################################################
  $AUTO_HELP = 1;

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
