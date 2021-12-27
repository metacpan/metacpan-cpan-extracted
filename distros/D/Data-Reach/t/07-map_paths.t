#!perl
use strict;
use warnings;
no warnings 'uninitialized';
use Test::More tests => 9;
use Test::NoWarnings;
use Data::Reach 'map_paths';

# test data
my $data = {
  foo => [ undef,
           'abc',
           {bar => {buz => 987}},
           1234,
          ],
  empty_array => [],
  empty_hash  => {},
  empty_slot  => undef,
  qux         => 'qux',
  stringref   => \"ref",
  refref      => \\"ref",
};


{
  my %all_paths  = map_paths {join(",", @_) => $_} $data;
  my $stringref  = delete $all_paths{stringref};
  my $refref     = delete $all_paths{refref};


  is_deeply \%all_paths,
            {'empty_slot'    => undef,
             'foo,0'         => undef,
             'foo,1'         => 'abc',
             'foo,2,bar,buz' => 987,
             'foo,3'         => 1234,
             'qux'           => 'qux', },  "initial paths";
  like $stringref, qr/^SCALAR\(/,          'stringref';
  like $refref,    qr/^REF\(/,             'refref';
}


{
  use Data::Reach qw/keep_empty_subtrees/;
  my %all_paths  = map_paths {join(",", @_) => $_} $data;
  my $stringref  = delete $all_paths{stringref};
  my $refref     = delete $all_paths{refref};
  my $empty_array= delete $all_paths{empty_array};
  my $empty_hash = delete $all_paths{empty_hash};


  is_deeply \%all_paths,
            {'empty_slot'    => undef,
             'foo,0'         => undef,
             'foo,1'         => 'abc',
             'foo,2,bar,buz' => 987,
             'foo,3'         => 1234,
             'qux'           => 'qux', }, "initial paths";
  like $stringref,   qr/^SCALAR\(/,       'stringref';
  like $refref,      qr/^REF\(/,          'refref';
  like $empty_array, qr/^ARRAY\(/,        "empty_array";
  like $empty_hash,  qr/^HASH\(/,         "empty_hash";
}


