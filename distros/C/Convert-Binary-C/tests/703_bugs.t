################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test::More tests => 11;
use Convert::Binary::C @ARGV;

my $code = <<ENDC;

struct test {
  unsigned a:2;
  unsigned b:2;
  unsigned c:28;
};

ENDC

my $c1 = Convert::Binary::C->new(ByteOrder => 'LittleEndian');

eval {
  $c1->parse($code);
  $c1->ByteOrder('BigEndian');
};

is($@, '', 'parse/configure');

my $c2 = Convert::Binary::C->new(ByteOrder => 'LittleEndian');

eval {
  $c2->ByteOrder('BigEndian');
  $c2->parse($code);
};

is($@, '', 'configure/parse');

my $data = pack "N", 0x60000003;

for my $c ($c1, $c2) {
  my $t = $c->unpack('test', $data);
  is($t->{a}, 1, 'a');
  is($t->{b}, 2, 'b');
  is($t->{c}, 3, 'c');
}

### Ooops, the hash/list iterators were not reentrant...

$c1->clean->parse(<<'ENDC');

struct hash
{
  struct hash *a;
  struct hash *b;
};

ENDC

$c1->tag('hash', Hooks => { unpack_ptr => [\&unpack_hash, $c1->arg(qw(SELF TYPE DATA))] });

{
  my $i;

  sub unpack_hash
  {
    my($self, $type, $ptr) = @_;
    ++$i < 3 ? $self->unpack($type, $self->pack($type, { a => $i, b => 10 + $i })) : $ptr;
  }
}

{
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };

  my $dummy = $c1->unpack('hash', $c1->pack('hash', { a => 0, b => 10 }));
  is(scalar @warn, 0, 'hash/list iterator reentrancy');

  ### An assertion in hook_call() could fail if a hook was called
  ### for a member that didn't actually exist in the hash.

  @warn = ();
  $dummy = $c1->unpack('hash', $c1->pack('hash', { a => 0 }));
  is(scalar @warn, 0, 'hook_call assertion failed');
}

$c1->clean->parse(<<'ENDC');
typedef int foo_t;
ENDC

$c1->tag('foo_t', Hooks => { unpack => \&foo });

is($c1->unpack('foo_t', $c1->pack('foo_t', 42)), 42, 'unpack with moved stack');

sub blow_stack
{
  return (1) x 2000;
}

sub foo
{
  my @a = blow_stack();
  $_[0];
}
