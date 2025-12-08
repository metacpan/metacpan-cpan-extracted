#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use Data::Dumper;

my %tests = (
  foo            => 'ssm://rds/mysql/host',
  bar            => 'ssm://rdxs/mysql/user',
  biz            => [ 'buz', 'baz' ],
  buz            => { foo => [ 1, 2, 3 ] },
  level          => '${loglevel}',
  log4perl_level => '${loglevel == 5 ? "DEBUG" : "INFO"}'
);

########################################################################
subtest 'indexed access' => sub {
########################################################################
  use_ok 'Config::Resolver';
  my $resolver = Config::Resolver->new;

  is( $resolver->get_parameter( \%tests, 'biz[1]' ), 'baz' );

  is( $resolver->get_parameter( \%tests, 'buz.foo[2]' ), 3 );
};

1;

