#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 39;

use Data::BitStream::XS;
my $v = Data::BitStream::XS->new;

my @vals;
my $val;
{
  $v->erase_for_write;
  $v->put_golomb(1, 124);
  $v->rewind_for_read;
  $val = $v->get_golomb(1, 1);
  is($val, 124);
}
{
  $v->erase_for_write;
  $v->put_golomb(sub { shift->put_unary(@_); }, 1, 124);
  #$v->put_golomb(1, 124);
  $v->rewind_for_read;
  #$val = $v->get_golomb(sub { shift->get_unary(@_); }, 1, 1);
  $val = $v->get_golomb(1, 1);
  is($val, 124);
}
{
  $v->erase_for_write;
  $v->put_golomb(sub { shift->put_delta(@_); }, 1, 124, 15);
  $v->rewind_for_read;
  $val = $v->get_golomb(sub { shift->get_delta(@_); }, 1, 1);
  is($val, 124);
  $val = $v->get_golomb(sub { shift->get_delta(@_); }, 1, 1);
  is($val, 15);
}
{
  $v->erase_for_write;
  $v->put_golomb(sub { shift->put_omega(@_); }, 1, 124, 15);
  $v->rewind_for_read;
  @vals = $v->get_golomb(sub { shift->get_omega(@_); }, 1, 2);
  is_deeply( \@vals, [124, 15], "golomb(1) 124,15");
}
{
  my @a = 0 .. 10;
  $v->erase_for_write;
  $v->put_golomb(sub { shift->put_fib(@_); }, 1, @a);
  $v->rewind_for_read;
  @vals = $v->get_golomb(sub { shift->get_fib(@_); }, 1, 68);
  #print "vals is ", join(',', @vals), "\n";
  is_deeply( \@vals, \@a, "golomb(1) 0-67");
}

$v->erase_for_write;
my @a = 0 .. 257;
my $nitems = scalar @a;
foreach my $k (0 .. 31) {
  my $m = 2*$k + 1;
  #$v->put_golomb(sub { shift->put_delta(@_); }, $m, @a);
  $v->put_golomb(
    sub { my $self = shift;
          #isa_ok $self, 'Data::BitStream::XS';
          die unless $v == $self;
          die unless $self->writing;
          $self->put_unary(@_); },
    $m, @a);
}

$v->rewind_for_read;
foreach my $k (0 .. 31) {
  my $m = 2*$k + 1;
  #my @v = $v->get_golomb($m, $nitems);
  my @v = $v->get_golomb(sub { shift->get_unary(@_); }, $m, $nitems);
  #my @v = $v->get_golomb(
  #  sub { my $self = shift;
  #        die unless $v == $self;
  #        $self->get_unary(@_); },
  #  $m, $nitems);
  is_deeply( \@v, \@a, "golomb($m) 0-257");
}

{
  # Store a 32-bit or 43-bit number using delta.
  # This is a crude test of 64-bit storage.
  my $n = ($v->maxbits < 43) ? 2908947141 : 4052739537881;
  $v->erase_for_write;
  $v->put_golomb(sub { shift->put_delta(@_); }, 1, $n);
  $v->rewind_for_read;
  $val = $v->get_golomb(sub { shift->get_delta(@_); }, 1, 1);
  is($val, $n, "deltagolomb encode $n");
}
