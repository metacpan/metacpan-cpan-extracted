# $Id: fst.t 561 2022-12-29 18:54:15Z whynot $
# Copyright 2012, 2013, 2022 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;
use 5.010;

package main;
use version 0.77; our $VERSION = version->declare( v2.3.2 );

use t::TestSuite qw| :diag :wraps |;
use Test::More tests => 43;

use Acme::FSM;

our( $bb, $rc, $stderr );
my $method = q|fst|;
my( $fste, $fsto ) = qw| lobster beans |;
my( $old, $new, $deep, $late ) = qw| entwistle barry boeblich fazzo |;
my $tag;

AFSMTS_class_wrap { diag_level => 10 };
isa_ok $bb, q|Acme::FSM|, q|constructed object|;
ok !keys %{$bb->{_}{fst}}, qq|initial {fst} isa empty|;

$tag = q|no args, no fste,|;
AFSMTS_method_wrap $method;
is_deeply [ scalar keys %{$bb->{_}{fst}}, $rc ], [ 0, undef ],
  qq|$tag queried|;
like $stderr, qr<(?m)^\Q[fst]: no args >, qq|$tag noted|;

$tag = q|one arg, fste isa unset,|;
AFSMTS_method_wrap $method, $fste;
is_deeply [ scalar keys %{$bb->{_}{fst}}, $rc ], [ 0, undef ],
  qq|$tag queried|;
like $stderr, qr<(?m)^\Q[fst]: ($fste): no such {fst} record>, qq|$tag noted|;

$tag = q|two args (SCALAR), fste isa unset,|;
AFSMTS_method_wrap $method, $fste => $old;
is_deeply [ scalar keys %{$bb->{_}{fst}}, $rc ], [ 0, undef ],
  qq|$tag queried|;
like $stderr, qr<(?m)^\Q[fst]: ($fste): no such {fst} record>, qq|$tag noted|;

$tag = q|three args, fste isa unset,|;
AFSMTS_method_wrap $method, $fste => $old => $deep;
is_deeply [ scalar keys %{$bb->{_}{fst}}, $rc ], [ 0, undef ],
  qq|$tag queried|;
like $stderr, qr<(?m)^\Q[fst]: ($fste): no such {fst} record>, qq|$tag noted|;

$tag = q|two args (HASH), fste isa unset,|;
my $elder = { $old => $late };
AFSMTS_method_wrap $method, $fste => $elder;
is_deeply [ scalar keys %{$bb->{_}{fst}}, $rc ], [ 1, undef ],
  qq|$tag queried|;
ok exists $bb->{_}{fst}{$fste}, qq|$tag {fst} is indeed updated|;
is_deeply $bb->{_}{fst}{$fste}, { %$elder },
  qq|$tag just created entry is correct|;
isnt $bb->{_}{fst}{$fste}, $elder, qq|$tag just created entry is copied|;
like $stderr, qr<(?m)^\Q[fst]: creating {$fste} >, qq|$tag noted|;

$tag = q|one arg, fste is set,|;
AFSMTS_method_wrap $method, $fste;
is_deeply
[ scalar keys %{$bb->{_}{fst}}, qq|$rc| ], [ 1, qq|$bb->{_}{fst}{$fste}| ],
  qq|$tag queried|;
is_deeply $rc, $elder, qq|$tag {fst} entry is returned|;

$tag = q|two args (SCALAR), fste is set, known key,|;
AFSMTS_method_wrap $method, $fste => $old;
is_deeply [ scalar keys %{$bb->{_}{fst}}, $rc ], [ 1, $late ],
  qq|$tag queried|;
is_deeply $bb->{_}{fst}{$fste}, $elder, qq|$tag {fst} entry stays intact|;

$tag = q|two args (SCALAR), fste is set, unknown key,|;
AFSMTS_method_wrap $method, $fste => $new;
is_deeply [ scalar keys %{$bb->{_}{fst}}, $rc ], [ 1, undef ],
  qq|$tag queried|;
is_deeply $bb->{_}{fst}{$fste}, $elder, qq|$tag {fst} entry stays intact|;

$tag = q|three args, fste is set, known key,|;
$elder->{$old} = $deep;
AFSMTS_method_wrap $method, $fste => $old => $deep;
is_deeply [ scalar keys %{$bb->{_}{fst}}, qq|$rc| ], [ 1, qq|$late| ],
  qq|$tag queried|;
is_deeply $bb->{_}{fst}{$fste}, $elder, qq|$tag {fst} entry is updated|;
like $stderr, qr<(?m)^\Q[fst]: updating {$fste}{$old} >, qq|$tag noted|;
AFSMTS_method_wrap $method, $fste;
is_deeply $rc, $elder, qq|$tag indeed it is|;

$tag = q|three args, fste is set, unknown key,|;
$elder->{$new} = $deep = q|fauchard|;
AFSMTS_method_wrap $method, $fste => $new => $deep;
is_deeply [ scalar keys %{$bb->{_}{fst}}, $rc ], [ 1, undef ],
  qq|$tag queried|;
is_deeply $bb->{_}{fst}{$fste}, $elder, qq|$tag {fst} entry is updated|;
like $stderr, qr<(?m)^\Q[fst]: creating {$fste}{$new} >, qq|$tag noted|;
AFSMTS_method_wrap $method, $fste;
is_deeply $rc, $elder, qq|$tag indeed it is|;

$tag = q|three args, fste is set, duplicate value,|;
$elder->{$new} = $late;
AFSMTS_method_wrap $method, $fste => $new => $late;
is_deeply [ scalar keys %{$bb->{_}{fst}}, $rc ], [ 1, $deep ],
  qq|$tag queried|;
is_deeply $bb->{_}{fst}{$fste}, $elder, qq|$tag {fst} entry is updated|;
like $stderr, qr<(?m)^\Q[fst]: updating {$fste}{$new} >, qq|$tag noted|;
AFSMTS_method_wrap $method, $fste;
is_deeply $rc, $elder, qq|$tag indeed it is|;

$tag = q|two args (HASH), other fste isa unset,|;
( $old, $late ) = qw| billy lazar |;
my $youngster = { $old => $late };
AFSMTS_method_wrap $method, $fsto => $youngster;
is_deeply [ scalar keys %{$bb->{_}{fst}}, $rc ], [ 2, undef ],
  qq|$tag queried|;
ok exists $bb->{_}{fst}{$fsto}, qq|$tag {fst} is indeed updated|;
is_deeply $bb->{_}{fst}{$fsto}, { %$youngster },
  qq|$tag just created entry is correct|;
isnt $bb->{_}{fst}{$fsto}, $youngster, qq|$tag just created entry is copied|;
like $stderr, qr<(?m)^\Q[fst]: creating {$fsto} >, qq|$tag noted|;
AFSMTS_method_wrap $method, $fste;
is_deeply $rc, $elder, qq|$tag other {fst} isn't affected|;

$tag = q|four args,|;
AFSMTS_method_wrap $method, qw| beans billy lazar contango |;
like $stderr, qr<(?m)^\Q[fst]: too many args (4)>, qq|$tag noted|;
is scalar keys %{$bb->{_}{fst}}, 2, qq|$tag {fst} is intact|;
AFSMTS_method_wrap $method, $fste;
is_deeply $rc, $elder, qq|$tag first {fst} isn't affected|;
AFSMTS_method_wrap $method, $fsto;
is_deeply $rc, $youngster, qq|$tag second {fst} isn't affected|;

# vim: set filetype=perl
