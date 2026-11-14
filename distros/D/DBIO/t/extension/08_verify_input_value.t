use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';
use DBIO::Extension;
use DBIO::Extension::Protocol;

# verify_input compares what an extension can see of its input before and
# after the call: the value, not the flags Perl keeps beside it. Reading a
# string as a number (or the other way round) changes those flags on a Perl
# before 5.36 and must not count as a change; adding, changing or removing
# data must.

sub mk {
  my ($name, %methods) = @_;
  our $n; my $class = "T::VerifyValue::\u$name" . ++$n;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Extension');
  *{"${class}::extension_interface"} = sub { 1 };
  *{"${class}::name"} = sub { $name };
  *{"${class}::$_"} = $methods{$_} for keys %methods;
  return { name => $name, class => $class, options => {}, installed => 1, version => '1', schema => 'public' };
}

# An extension running $code on the model it claims on.
sub run_claims {
  my ($code, $model) = @_;
  my $entry = mk(x => claims => sub { $code->($_[1], $_[2]); [] });
  my $p = DBIO::Extension::Protocol->new(entries => [$entry], driver => {}, verify_input => 1);
  return $p->claims($model);
}

my $code = sub { 1 };
sub model { return { table => 'a', n => '10', size => 3, list => [ 'x', 1 ], re => qr/ab/i, code => $code, ref => \ 'text' } }

# --- reading changes nothing ---------------------------------------------------------
lives_ok { run_claims(sub { my $x = $_[0]{n} + 0; my $y = "$_[0]{size}"; my $z = $_[0]{list}[1] . '' }, model()) }
  'reading a string as a number and a number as a string is no change';
lives_ok { run_claims(sub { my $x = $_[0]{re}; my $y = $_[0]{code}; 1 }, model()) }
  'a model holding a Regexp and a code reference passes the check';
lives_ok { run_claims(sub { my $x = $_[1]{self}{version} + 0; my $y = "$_[1]{restricted}" }, model()) }
  'reading the context in another context is no change';

{
  my $cycle = { name => 'c' };
  $cycle->{self} = $cycle;
  lives_ok { run_claims(sub { 1 }, $cycle) } 'a cyclic model is compared without looping';
}

# --- real changes are still found ---------------------------------------------------------
my %mutation = (
  'a key added'               => sub { $_[0]{extra} = 1 },
  'a value changed'           => sub { $_[0]{table} = 'b' },
  'a number changed'          => sub { $_[0]{size} = 4 },
  'an element removed'        => sub { pop @{ $_[0]{list} } },
  'an element added'          => sub { push @{ $_[0]{list} }, 'y' },
  'a key removed'             => sub { delete $_[0]{table} },
  'undef made an empty string' => sub { $_[0]{u} = '' },
  'a Regexp replaced'         => sub { $_[0]{re} = qr/cd/ },
  'a code reference replaced' => sub { $_[0]{code} = sub { 2 } },
  'a scalar reference content' => sub { ${ $_[0]{ref} } = 'other' },
);
for my $what (sort keys %mutation) {
  my $m = model();
  $m->{u} = undef;
  my $mutate = $mutation{$what};
  throws_ok { run_claims(sub { $mutate->($_[0]) }, $m) } qr/changed its input in claims/,
    "$what is found";
}

{
  my $m = { obj => bless({ v => [ 1, 2 ] }, 'T::VerifyValue::Obj') };
  throws_ok { run_claims(sub { push @{ $_[0]{obj}{v} }, 3 }, $m) } qr/changed its input in claims/,
    'a change inside a blessed object is found';
  my $m2 = { obj => bless({ v => 1 }, 'T::VerifyValue::Obj') };
  throws_ok { run_claims(sub { bless $_[0]{obj}, 'T::VerifyValue::Other' }, $m2) } qr/changed its input in claims/,
    'a changed class of an object is found';
}

for my $what (
  [ restricted => sub { $_[1]{restricted} = 1 } ],
  [ peers      => sub { $_[1]{peers}{ghost} = {} } ],
  [ self       => sub { $_[1]{self}{version} = '2' } ],
  [ connection => sub { $_[1]{connection_schema} = 'other' } ],
) {
  my ($key, $mutate) = @$what;
  throws_ok { run_claims($mutate, model()) } qr/changed its context in claims/,
    "a changed $key of the context is found";
}

done_testing;
