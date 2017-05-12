#!perl

use strict;
use warnings;

use Data::Find qw( diter dfind dwith );
use Test::More;

my @cases = (
  {
    name => 'all',
    args => [
      {
        ar => [ 1, 2, 3 ],
        ha => { one => 1, two => 2, three => 3 }
      }
    ],
    expect => [
      '{ar}[0]',     '{ar}[1]', '{ar}[2]', '{ha}{one}',
      '{ha}{three}', '{ha}{two}',
    ],
  },
  {
    name => 'odd',
    args => [
      {
        ar => [ 1, 2, 3 ],
        ha => { one => 1, two => 2, three => 3 }
      },
      sub {
        my $v = shift;
        defined $v && !ref $v && $v % 2 == 1;
       }
    ],
    expect => [ '{ar}[0]', '{ar}[2]', '{ha}{one}', '{ha}{three}', ],
  },
  {
    name => 'three',
    args => [
      {
        ar => [ 1, 2, 3 ],
        ha => { one => 1, two => 2, three => 3 }
      },
      3,
    ],
    expect => [ '{ar}[2]', '{ha}{three}', ],
  },
  {
    name => 'circular',
    args => sub {
      my $foo = { ar => [ 'a', 'b', 'c' ], };
      $foo->{me} = $foo;
      return [ $foo, qr{c} ];
    },
    expect => [ '{ar}[2]', ],
  },
);

plan tests => @cases * 2;

for my $case ( @cases ) {
  my $name = $case->{name};
  my $args = $case->{args};
  $args = $args->() if 'CODE' eq ref $args;
  my @got  = dfind @$args;
  my @got2 = ();
  dwith @$args, sub {
    push @got2, shift;
  };
  is_deeply [@got],  $case->{expect}, "$name: dfind";
  is_deeply [@got2], $case->{expect}, "$name: dwith";
}

# vim:ts=2:sw=2:et:ft=perl

