#!/usr/bin/perl

use v5.22;
use warnings;

use Test2::V0;

use B qw( svref_2object walkoptree );

use Data::Checks qw( Defined Object Str Isa Maybe NumRange StrEq );

sub count_ops
{
   my ( $code ) = @_;
   my %opcounts;

   # B::walkoptree() is stupid
   #   https://github.com/Perl/perl5/issues/19101
   no warnings 'once';
   local *B::OP::collect_opnames = sub {
      my ( $op ) = @_;
      $opcounts{ $op->name }++ unless $op->name eq "null";
   };
   walkoptree( svref_2object( $code )->ROOT, "collect_opnames" );

   return %opcounts;
}

sub const_inlined_ok
{
   my ( $code, $name ) = @_;

   my %opcounts = count_ops $code;
   is( $opcounts{const},         1, "$name uses 1 x OP_CONST" );
   is( $opcounts{entersub} // 0, 0, "$name does not use OP_ENTERSUB" );
}

# Calls to 0arg constraints get inlined
const_inlined_ok sub { Defined }, 'Defined';
const_inlined_ok sub { Str     }, 'Str';
const_inlined_ok sub { Object  }, 'Object';

# Calls to 1arg constraints get inlined if possible
const_inlined_ok sub { Isa "Some::Class" }, 'Isa';
const_inlined_ok sub { Maybe Str },         'Maybe Str';

# Calls to 2arg constraints
const_inlined_ok sub { NumRange 0, 10 }, 'NumRange 0, 10';

# Calls to narg constraints
const_inlined_ok sub { StrEq "A", "B", "C" }, 'StrEq A, B, C';
const_inlined_ok sub { StrEq qw( A B C )   }, 'StrEq qw( A B C )';
# TODO: const_inlined_ok sub { StrEq "A" .. "C"    }, 'StrEq A .. C';

# Non-inlinable calls still work
my %opcounts = count_ops sub { my $constraint = Maybe Isa $_[0] };
is( $opcounts{entersub}, 2, 'Maybe Isa $_[0] still has two OP_ENTERSUB' );

done_testing;
