#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;
use Data::FormValidator;

my %FORM = (
  stick => 'big',
  speak => 'softly',
  mv    => [ 'first', 'second' ],
);

my $results = Data::FormValidator->check(
  \%FORM,
  {
    required => [ 'stick', 'fromsub', 'whoami' ],
    optional => [ 'mv',    'opt_1',   'opt_2', ],
    defaults => {
      fromsub => sub { return "got value from a subroutine"; },
    },
    defaults_regexp_map => {
      qr/^opt_/ => 2,
    },
  } );

ok( $results->valid('stick') eq 'big', 'using check() as class method' );
is( $results->valid('stick'),
  $FORM{stick}, 'valid() returns single value in scalar context' );
my @mv = $results->valid('mv');
is_deeply( \@mv, $FORM{mv}, 'valid() returns multi-valued results' );
my @stick = $results->valid('stick');
is_deeply(
  \@stick,
  [ $FORM{stick} ],
  'valid() returns single value in list context'
);
ok( $results->valid('fromsub') eq "got value from a subroutine",
  'usg CODE references as default values' );

{
  is( $results->valid('opt_1'), 2, "defaults_regexp works (case 1)" );
  is( $results->valid('opt_2'), 2, "defaults_regexp works (case 1)" );

}
