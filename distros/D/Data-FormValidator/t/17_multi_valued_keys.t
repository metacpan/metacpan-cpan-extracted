#!/usr/bin/env perl
use strict;
use warnings;
use lib ( '.', '../t' );
use Test::More tests => 8;
use Data::FormValidator;

# This script tests validating keys with multiple data
my $input_hash = {
  single_value          => ' Just One ',
  multi_values          => [ ' One ', ' Big ', ' Happy ', ' Family ' ],
  re_multi_test         => [qw/at the circus/],
  constraint_multi_test => [qw/12345 22234 oops/],
};
my $input_profile = {
  required =>
    [qw/single_value multi_values re_multi_test constraint_multi_test/],
  filters       => [qw/trim/],
  field_filters => {
    single_value => 'lc',
    multi_values => 'uc',
  },
  field_filter_regexp_map => {
    '/_multi_test$/' => 'ucfirst',
  },
  constraints => {
    constraint_multi_test => 'zip',
  },
};

my $validator = new Data::FormValidator( { default => $input_profile } );

my ( $valids, $missings, $invalids, $unknowns );
eval {
  ( $valids, $missings, $invalids, $unknowns ) =
    $validator->validate( $input_hash, 'default' );
};

is( $valids->{single_value},
  'just one', 'inconditional filters still work with single values' );

is( lc $valids->{multi_values}->[0],
  lc 'one', 'inconditional filters work with multi values' );

is( $valids->{multi_values}->[0],
  'ONE', 'field filters work with multiple values' );

is( $valids->{re_multi_test}->[0],
  'At', 'Test the filters applied to multiple values by RE work' );

ok( !$valids->{constraint_multi_test},
  'If any of the values fail the constraint, the field becomes invalid' );

my $r;
eval
{
  $r = Data::FormValidator->check( { undef_multi => [undef] },
    { required => 'undef_multi' } );
};
diag "error: $@" if $@;
ok( $r->missing('undef_multi'),
  'multi-valued field containing only undef should be missing' );

my $v;
eval { $v = $r->valid('undef_multi'); };
diag "error: $@" if $@;
ok( !$v,
  'multiple valued fields containing only undefined values should not be valid'
);

###

eval {
  $r = Data::FormValidator->check( {
      cc_type => ['Check'],
    },
    {
      required     => 'cc_type',
      dependencies => {
        cc_type => {
          Check => [qw( cc_num )],
          Visa  => [qw( cc_num cc_exp cc_name )],
        },
      },
    } );
};
diag "error: $@" if $@;

ok( $r->missing('cc_num'),
  'a single valued array should still trigger the dependency check' );
