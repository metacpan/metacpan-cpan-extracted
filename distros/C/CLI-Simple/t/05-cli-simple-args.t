#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use English qw(no_match_vars);

use Test::More;

use_ok('CLI::Simple');

use vars qw(@ARGV);

my @options = qw(
  foo
  bar=s
);

########################################################################
subtest 'get_args' => sub {
########################################################################

  local @ARGV = qw(foo bar biz buz);

  my $app = CLI::Simple->new(
    commands     => { foo => sub { return 0 } },
    option_specs => \@options
  );

  my @args = $app->get_args();

  # - get list of all args
  ok( 3 == @args,                        'got three args' );
  ok( 'barbizbuz' eq join( q{}, @args ), 'got bar biz buz' );

  # -- get hash ref of keys
  my $args = $app->get_args(qw(bar biz buz));

  ok( ref $args && keys %{$args} == 3, 'got hash ref' );
  is_deeply( $args, { bar => 'bar', biz => 'biz', buz => 'buz' }, 'got hash values' );

  # -- skip a key
  my %args = $app->get_args( 'bar', undef, 'buz' );
  ok( 2 == keys %args, 'got two args' );
  is_deeply( \%args, { bar => 'bar', buz => 'buz' }, 'got bar buz' );
};

done_testing;

1;

__END__

1;

1;
